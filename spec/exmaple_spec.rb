describe [DefDsl,DefDSL].join' or ' do
  after { remove_const :My if defined? My }

  example 'in module' do
    module My
      # nice looking recursive dsl definition
      class File < Struct.new :name; end
      class Dir < Struct.new :name
        Dir = Dir
        File = File
      end

      extend DefDSL
      def_dsl Dir
      def_dsl File

      file 'root.txt'
      dir 'dir' do
        dir 'inner' do
          dir 'empty'
          file 'any'
        end
      end

      so.should == {file: so1(:file), dir: so1(:dir)}

      so1(:file).name.should == 'root.txt'
      so1(:dir).name.should == 'dir'
      (inner = so1(:dir).send(:so1,:dir)).name.should == 'inner'
      inner.send(:so2,:dir).map(&:name).should == ['empty']
      inner.send(:so2,:file).map(&:name).should == ['any']
    end
  end
end