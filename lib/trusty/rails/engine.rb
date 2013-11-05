require 'trusty/rails/controller_extensions'

module Trusty
  module Rails
    class Engine < ::Rails::Engine
      
      initializer "trusty.rails.initialize_views" do |app|
        ActiveSupport.on_load :action_view do
          # TODO: Add view extensions
        end
      end
      
      initializer "trusty.rails.initialize_controllers" do |app|
        ActiveSupport.on_load :action_controller do
          include ControllerExtensions
        end
      end
      
      if defined? Rake
        initializer "trusty.rails.initialize_rake" do |app|
          require 'trusty/rake'
        end
      end
      
      if defined? ExceptionNotification
        initializer "trusty.rails.initialize_exception_notification" do |app|
          require 'trusty/exception_notification'
        end
      end
      
    end
  end
end