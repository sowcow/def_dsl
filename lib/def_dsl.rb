# PROTIP:
#   use mixins for behavior, and classes only for classification!
#
# extended at the end of context class
# rspec!!!!!!!!!!!!!


# def def_dsl klass
# end

require "def_dsl/version"

module DefDsl


  def def_dsl const
    define_dsl! self, [[const.name.to_s.underscore(self), const]]
  end
  alias define_dsl def_dsl  


  def shallow_constants who
    (who.constants - who.superclass.constants).map { |name| * = name.to_s.underscore, who.const_get(name) }
  end


  def define_dsl! who, constants=shallow_constants(who) # ...
    # constants = constants.nil?? shallow_constants(who) : constants_info(constants)
    constants.each do |mini, const|

      next if const.included_modules.include? So
      who.send :include, So
      define_dsl! const if const.is_a? Class

      who.class_eval do
        define_method(mini) do |*a,&b|
          so mini,*a,&b
        end
      end

      # const.send :include, So if const.is_a? Module # or even class
      # who.send :include, So if who.is_a? Module # or even class
      if who.class == Module
        who.send :module_function, mini
        who.send :module_function, :so
        who.send :module_function, :so1
        who.send :module_function, :so2
      end      
    end
  end 

  module So
    def so klass_name=nil,*a,&b
      return @so if klass_name.nil?

      klass_name = klass_name.to_sym

      if self.class == Module
        klass = self.const_get(klass_name.to_s.camelize)
      else
        klass = self.class.const_get(klass_name.to_s.camelize)
      end

      obj = klass.new(*a) #,&b)
      obj.instance_eval &b if b
      (@so ||= {}).tap { |h| h[klass_name] = h[klass_name] ? [h[klass_name], obj].flatten(1) : obj }
    end
    def so1(name)
      value = @so[name]
      value.is_a?(Array) ? value.last : value
    end
    def so2(name)
      value = @so[name]
      value.is_a?(Array) ? value : [value]
    end    
  end

end
DefDSL = DefDsl


class String
  def camelize
    self.split(/[^a-z0-9]/i).map{|w| w.capitalize}.join
  end

  def underscore(relative_to=nil)
    name = relative_to.nil?? self : self.sub(/^#{ relative_to.to_s }::/,'')
    name.gsub(/::/, '/').
         gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
         gsub(/([a-z\d])([A-Z])/,'\1_\2').
         tr("-", "_").
         downcase
  end
end