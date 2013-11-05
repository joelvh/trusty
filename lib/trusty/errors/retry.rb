require 'trusty/errors/exception_handlers'

module Trusty
  module Errors
    module Retry
      include ExceptionHandlers
      
      # retry a block of code
      def retry_block(options = {}, &block)
        options = {
          :retry => 1,
          :data => {},
          :type => StandardError
        }.merge(options)
        
        retries = case options[:retry]
          when true
            1
          when Integer
            options[:retry]
          else
            0
          end
        
        types = [ options[:type] ].flatten.compact
        
        begin
          yield
        rescue *types => ex
          if retries > 0
            return self.send(__method__, options.merge(:retry => retries - 1), &block)
          else
            notify_exception(ex, :data => options[:data], :raise => true)
          end
        end
      end
      
      # helper method to redefine method (a la alias_method_chain, etc)
      def retry_method(method, options = {})
        define_method method do |*args, &block|
          super_method = method(:super)
          retry_block options do
            super_method(*args, &block)
          end
        end
      end
      
    end
  end
end