describe 'DefDsl or DefDSL' do
  after { remove_const :My if defined? My }

  example 'usage inside module' do
    module My
      # nice looking recursive dsl definition
      class File < Struct.new :name; end
      class Dir < Struct.new :name
        Dir = Dir
        File = File
      end

      extend DefDSL! # accepts optional black list of classes

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


  example 'usage inside object' do
    class My

      class File < Struct.new :name; end
      class Dir < Struct.new :name
        Dir = Dir
        File = File
      end

      extend DefDSL
      def_dsl # accepts optional black list of classes

      def initialize
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
    My.new
  end


  example 'explicit dsl method name definition' do
    module My
      # nice looking recursive dsl definition
      class AFile < Struct.new :name; @dsl = :file end
      class ADir < Struct.new :name
        @dsl = :dir
        ADir = ADir
        AFile = AFile
      end

      extend DefDSL
      def_dsl #ADir, AFile

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


  example 'redefine feed_block' do
    module My
      # nice looking recursive dsl definition
      class File < Struct.new :name
        def feed_block &block
          @block = block
        end
      end
      class Dir < Struct.new :name
        Dir = Dir
        File = File
      end

      extend DefDSL
      def_dsl #Dir, File

      file 'root.txt' do
        this.block.should_be just stored.in_ivar
      end
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

      so1(:file).instance_eval { @block }.nil?.should == false
    end
  end


  example 'lazy evaluation' do # useless
    pending
    class My
      class File < Struct.new :name; end
      class Dir < Struct.new :name
        Dir = Dir
        File = File
      end

      extend DefDSL
      def_dsl #Dir, File

      def initialize &block
        @block = block
        # block ? instance_eval(&block) : raise

        # so.should == {file: so1(:file), dir: so1(:dir)}

        # so1(:file).name.should == 'root.txt'
        # so1(:dir).name.should == 'dir'
        # (inner = so1(:dir).send(:so1,:dir)).name.should == 'inner'
        # inner.send(:so2,:dir).map(&:name).should == ['empty']
        # inner.send(:so2,:file).map(&:name).should == ['any']        
      end

      def feed data
        @so = nil
        @data = data
        instance_eval(&@block)
      end
    end

    hook = nil

    my = My.new do
      file 'root.txt'
      hook = @data

      dir 'dir' do
        raise 123
        dir 'inner' do
          dir 'empty'
          file 'any'
        end
      end      
    end  

    my.feed 1
    hook.should == 1
    my.feed 2
    hook.should == 2
  end


  example 'return [] if value.nil?' do
    pending
  end  


  example 'easy dsl' do
    module My
      class Use123; end

      extend DefDsl!
      use123
      so.should == {use123: so1(:use123)}
    end
  end

  example 'declarative way to remember block' do
    module My
      class Blocky
        @lazy = true # should remember block to be used in other context
      end            # lazy is too short to ignore
      extend DefDSL!

      blocky do |x|
        @a = (@a || 0) + 1
      end

      context = Object.new
      so1(:blocky).call!(context)
      context.instance_eval { @a }.should == 1

      #so.should == {file: so1(:file), dir: so1(:dir)}
      #class Blocky < Struct.new :shit
      #end
      #extend DefDsl #(Block)
      #def_dsl Blocky
      #blocky do
      #  @a = 123
      #end
      #expect { my.so1(:block).call! }.to change { my.so1(:block).instance_eval{@a} }.from(nil).to(123)
    end
  end
end
