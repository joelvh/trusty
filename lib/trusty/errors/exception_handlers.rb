require 'active_support'

module Trusty
  module Errors
    module ExceptionHandlers
      
      def try_with_data(data, &block)
        begin
          yield
        rescue => exception
          notify_exception exception, :data => data, :raise => true
        end
      end
      
      # include in classes
      def notify_exception(exception, options = {})
        
        options[:env] ||= respond_to?(:request) ? request.env : respond_to?(:env) ? env : nil
        
        ActiveSupport::Notifications.publish("trusty.errors.notify_exception", exception, options)
        
        raise exception if options[:raise] == true
      end
      
    end
  end
end