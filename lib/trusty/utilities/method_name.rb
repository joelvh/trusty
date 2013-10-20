module Trusty
  module Utilities
    class MethodName
      
      attr_reader :name, :base, :convention
      
      def initialize(name)
        @name = name
        # returns a method name and its ending (e.g. "config?" returns ["config", "?"])
        @base, @convention = name.to_s.match(/\A(\w+?)(\W+)?\Z/).to_a.slice(1, 2)
      end
      
      # indicates that it's not a vanilla method name
      def special?
        base == nil || convention != nil
      end
      
      # has a name and is not shorthand (e.g. "[]", "[]=", or "<<" type method)
      def named?
        base != nil
      end
      
      # has no name and is probably just "[]", "[]=", or "<<" type method
      def shorthand?
        !named?
      end
      
      def boolean?
        convention == '?'
      end
      
      def modifier?
        convention == '!'
      end
      
      def value_for(target, *args, &block)
        if target.respond_to?(name) || !target.respond_to?(base)
          method_value_for(target, name, *args, &block)
        else
          base_value_for(target, *args, &block)
        end
      end
      
      def base_value_for(target, *args, &block)
        method_value_for(target, base, *args, &block)
      end
      
      def define_for(target, options = { :on => :all })
        class_result    = define_with_method :define_method, target           unless options[:on] == :instance
        instance_result = define_with_method :define_singleton_method, target unless options[:on] == :class
        
        # indicate if a method was defined
        class_result == true || instance_result == true
      end
      
      private
      
      def define_with_method(define_method_name, target)
        # create helper method that sees if a config is blank
        if boolean? && target.respond_to?(define_method_name)
          helper = self
          target.send define_method_name, name do |*args, &block|
            helper.base_value_for(self, *args, &block)
          end
          
          true
        else
          false
        end
      end
      
      def method_value_for(target, method_name, *args, &block)
        value = target.send(method_name, *args, &block)
        
        if boolean?
          value != nil && (!value.respond_to?(:empty?) || !value.empty?)
        else
          value
        end
      end
      
    end
  end
end