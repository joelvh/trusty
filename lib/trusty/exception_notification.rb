require 'exception_notification'

module Trusty
  module ExceptionNotification
    
  end
end

# register exception listener for Trusty::Errors::ExceptionHelper and Trusty::ExceptionNotification::Rake

ActiveSupport::Notifications.subscribe("trusty.errors.notify_exception") do |exception, options|
  if env = options.delete(:env)
    ExceptionNotifier::Notifier.exception_notification(env, exception, options).deliver!
  else
    ExceptionNotifier::Notifier.background_exception_notification(exception, options).deliver!
  end
end