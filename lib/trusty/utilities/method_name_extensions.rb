module Trusty
  module Utilities
    module MethodNameExtensions
      
      def self.included(base)
        base.extend self
      end
      
      def method_name_info(method_name)
        @method_name_info ||= {}
        @method_name_info[method_name.to_s] ||= MethodName.new(method_name)
      end
      
      # dynamically add methods that forward to config
      def method_missing(name, *args, &block)
        method_name = method_name_info(name)
        
        if method_name.define_for(self)
          method_name.value_for(self)
        else
          super
        end
      end
    end
  end
end