require 'rake'
require 'trusty/errors/exception_handlers'

# FROM:
# https://github.com/thoughtbot/airbrake/blob/master/lib/airbrake/rake_handler.rb
# Patch Rake::Application to handle errors with Airbrake
module Trusty
  module Rake
    include ::Trusty::Errors::ExceptionHandlers
  
    def self.included(base)
      base.class_eval do
        alias_method :display_error_message_without_email, :display_error_message
        alias_method :display_error_message, :display_error_message_with_email
      end
    end
  
    def self.handle_exceptions!
      ::Rake.application.instance_eval do
        class << self
          # include this module
          include Rake
        end
      end
    end
    
    def display_error_message_with_email(exception)
      notify_exception(exception)
      display_error_message_without_email(exception)
    end
  end
end

# wire up exception handling in Rake tasks
Trusty::Rake.handle_exceptions!