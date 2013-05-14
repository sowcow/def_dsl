# PROTIP:
#   use mixins for behavior, and classes only for classification!
#
# extended at the end of context class
# rspec!!!!!!!!!!!!!
# mutant?
# So is'nt tested
# more comments inside method - more dumb decisions it has!

require "def_dsl/version"
require 'meta_module'

#def DefDsl *classes
#  DefDsl::Dsl.new *classes
#end
#alias DefDSL DefDsl

# shortcut to extend and define
def DefDsl! *black_list
  Module.new do
    define_singleton_method :extended do |target|
      target.send :extend, DefDsl
      target.def_dsl *black_list
    end
  end
end
alias DefDSL! DefDsl!

module DefDsl

  module Lazy
    def feed_block &b; @block_ = b end
    def block!; @block_ end
    def call! ctx; ctx.instance_eval &block! end
  end

  # todo: test so, trash(?)
  def def_dsl trash = []
    DefDsl.traverse self, trash do |who|
      who.send :include, So
      who.send :include, Lazy if who.instance_eval { @lazy }

      DefDsl.shallow(who, trash).each do |mod|
        mini = mod.name.underscore # .....
        method = mod.instance_eval { @dsl } ||  mod.name.underscore

        who.module_eval do
          define_method method do |*a,&b|
            so [mini,method],*a,&b # artifact...
          end
        end
        # or check superclass if respond for meta_modules + test
        if who.class == Module
          who.send :module_function, method
        end
      end
    end
  end

  # todo: to test optional black list or run mutant :)
  #
  # @param given [Class, Module]
  # @return [Array<Class, Module>] that explicitly defined in given
  def shallow given, trash = []
    if given.class == Module;   given.constants.map { |x| given.const_get x }
    elsif given.class == Class
      here = given.constants.map { |x| given.const_get x }
      sup = given.superclass
      other = sup.constants.map { |x| sup.const_get x }
      here - other
    else []
    end - trash
  end
  module_function :shallow # explicit_const or other name?

  # @param klass
  # @param trash [Class, Module, Array<Class, Module>]
  #   optional black list of entities to visit and return
  # @return [Array<Class, Module>]
  def all_modules klass, trash = []
    trash = [*trash]
    trash += [klass]
    children = shallow(klass, trash)
    all = [klass, children.
           map { |x| all_modules x, trash + children }].
           flatten.select { |x| Module === x }
    all
  end
  module_function :all_modules

  # implicit way to use instance_eval, by passing block with zero arity
  # @param block [Proc]
  # @return [Proc]
  def arity_based &block
    block.arity == 0 ? proc { |obj| obj.instance_eval &block }
                     : block
  end
  module_function :arity_based

  # traverse tree of classes and modules, acts {arity_based}
  #
  # @param target [Class, Module]       root of search tree
  # @param trash [Array<Class, Module>] black list of entities to visit and yield
  # @yield [Class, Module]              once per entity
  def traverse target, trash = [], &block
    all_modules(target, trash).each &DefDsl.arity_based(&block)
  end
  module_function :traverse

  #include MetaModule
  #class DSL < MModule
  #  def initialize(*classes) @classes = classes end
  #  used do |x|
  #    x.extend DefDsl
  #    @classes.each { |c| x.def_dsl c }
  #  end
  #end
  #Dsl = DSL



  #
  #
  #
  #
  #######################################################
  #
  #
  #
  #



  #def def_dsl *const
  #  const.each do |const|
  #    define_dsl! self, [[const.name.to_s.underscore(self), const]]
  #  end
  #end
  #alias define_dsl def_dsl  


#  def shallow_constants who
#    (who.constants - who.superclass.constants).map { |name| * = name.to_s.underscore, who.const_get(name) }
#  end
#
#
#  def define_dsl! who, constants=shallow_constants(who) # ...
#    # constants = constants.nil?? shallow_constants(who) : constants_info(constants)
#    return if who.included_modules.include? So
#    who.send :include, So
#    constants.each do |mini, const|
#
#      #next if who.included_modules.include? So
#      #who.send :include, So
#      next if const.included_modules.include? So
#      const.send :include, So
#      #who.send :include, So
#      
#      define_dsl! const if const.is_a? Class
#
#      meth =  const.instance_eval { @dsl } || mini
#
#      who.class_eval do
#        define_method(meth) do |*a,&b|
#          so [mini,meth],*a,&b
#        end
#      end
#
#      # const.send :include, So if const.is_a? Module # or even class
#      # who.send :include, So if who.is_a? Module # or even class
#      if who.class == Module
#        who.send :module_function, meth
#        who.send :module_function, :so
#        who.send :module_function, :so1
#        who.send :module_function, :so2
#      end      
#    end
#  end 

  module So
    def feed_block &block
      instance_eval &block
    end

    def so klass_name=nil,*a,&b
      return @so if klass_name.nil?

      klass_name, label = if klass_name.is_a? Array
                            klass_name.map &:to_sym
                          else
                            [klass_name.to_sym, klass_name.to_sym]
                          end

      if self.class == Module
        klass = self.const_get(klass_name.to_s.camelize)
      else
        klass = self.class.const_get(klass_name.to_s.camelize)
      end

      obj = klass.new(*a) #,&b)
      # obj.instance_eval &b if b
      obj.feed_block &b if b
      (@so ||= {}).tap { |h| h[label] = h[label] ? [h[label], obj].flatten(1) : obj }
    end
    def so1(name)
      value = @so[name]
      value.is_a?(Array) ? value.last : value
    end
    def so2(name)
      return [] unless @so.key? name
      value = @so[name]
      value.is_a?(Array) ? value : [value]
    end    

    def self.included target
      if target.class == Module # class.superclass for meta_module...
        target.send :module_function, :so
        target.send :module_function, :so1
        target.send :module_function, :so2
      end
    end
  end


end
DefDSL = DefDsl


class String
  def camelize
    self.split(/[^a-z0-9]/i).map{|w| w.capitalize}.join
  end

  # just last name
  def underscore    #(relative_to=nil)
    #name = relative_to.nil?? self : self.sub(/^#{ relative_to.name.to_s }::/,'')
    name = self
    name.gsub(/::/, '/').
         gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
         gsub(/([a-z\d])([A-Z])/,'\1_\2').
         tr("-", "_").
         downcase.
         split('/').last
  end
end
__END__
  #def def_dsl *classes
  #  classes.any?? def_dsl!(classes) : def_dsl!
  #end
  #def def_dsl #*classes #=shallow(self)
  #  classes
  #  classes.each do |klass|
  #    klass.def_dsl_shallow # WTF?  #klass
  #  end
  #  #magic = So
  #  #self.send :include, magic #unless self.included_modules.include? magic
  #  #p self
  #  #classes.each do |klass|
  #  #  DefDsl.include_recursively klass, magic
  #  #end
  #end
  #def def_dsl_shallow targets = shallow(self); root = self
  #  [*targets].each do |x|
  #    meth = x.instance_eval { @dsl } || x.name.to_s.underscore(root)
  #    root.class_eval do
  #      define_method(meth) do |*a,&b|
  #        #so [mini,meth],*a,&b
  #      end
  #    end
  #    if root.class == Module
  #      root.send :module_function, meth
  #      #who.send :module_function, :so
  #      #who.send :module_function, :so1
  #      #who.send :module_function, :so2
  #    end      
  #  end
  #end

  ####def include_recursively target, mod, &block
  ####  all_modules(target).each do |x|
  ####    x.send :include, mod
  ####    x.instance_eval &block if block
  ####  end
  ####end
  ####module_function :include_recursively
  ####module_function :all_modules, :shallow
