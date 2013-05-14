describe DefDsl,:focus do
  #subject { DefDsl }
  after { remove_const :My if defined? :My }
  
  describe '#def_dsl_shallow' do
    it 'defines dsl methods for each shallow nested module if no argument given' do
      module My
        A = Class.new
        B = Module.new
        extend DefDsl
        extend RSpec::Matchers
        expect { def_dsl_shallow }.to change { (a && b) rescue :err }.from(:err)
      end
    end
    it 'defines dsl methods only for given classes/modules' do
      module My
        A = Class.new
        B = Module.new
        extend DefDsl
        extend RSpec::Matchers
        expect { def_dsl_shallow A }.to change {
          [:a,:b].select { |x| respond_to? x } }.from([]).to([:a])
      end
    end
  end

  #describe 'def_dsl' do
  #  it 'calls def_dsl_shallow for self and each nested module recursively' do
  #    module My
  #      A = Module.new
  #      class B
  #        C = Class.new
  #      end

  #      extend DefDsl
  #      extend RSpec::Matchers
  #      ########## DefDsl.should_receive(:def_shallow_dsl) ###
  #      def_dsl
  #      expect { def_dsl }.to change {
  #        respond_to?(:a) # && respond_to?(:b) && B.new.respond_to?(:c)
  #      }.from(false).to(true)
  #    end
  #  end
  #  it 'include ***crap*** in self' do#.include_recursively for given module' do
  #    module My
  #      class A; end
  #      #DefDsl.should_receive(:include_recursively).with(My, DefDsl::So)
  #      extend DefDsl
  #      extend RSpec::Matchers
  #      expect { My.def_dsl A }.to change { My.included_modules }
  #    end
  #  end
  #end

  describe '.include_recursively' do
    it 'includes second module into first and all its children' do
      module My
        @rec = Module.new
        class A
        end
        class B
          module C
          end
        end

        DefDsl.include_recursively My, @rec
        [A, B, B::C].each do |x|
          x.included_modules.include?(@rec).should == true
        end
      end
    end

    it 'runs block in context of each module after inclusion only once per target' do
      module My
        @rec = Module.new
        class A
        end
        class B
          module C
            A = A
            X = A
            Y = B
          end
        end
        DefDsl.include_recursively My, @rec do
          @count = (@count || 0) + 1
        end
        [A, B, B::C, B::C::A, B::C::X, B::C::Y].each do |x|
          x.instance_eval { @count }.should == 1
        end
      end
    end
  end

  describe '.all_modules' do
    # todo: returns '' do instead of it '' do 
    it 'returns all unique nested modules and classes' do
      module My
        ODDMy = My
        ODD = 1
        A = Class.new
        class B
          ODDB = B
          ODDA = A
          C = Module.new
          ODD = 1
          module D
            ODDB = B
            E = Module.new
            ODD = 1
          end
        end
        module F
          ODD = 1
          G = Module.new
        end
      end

      DefDsl.all_modules(My).map(&:name).map{|x|x.split('::').last}.should == ['My',*'A'..'G']
    end
  end
end
