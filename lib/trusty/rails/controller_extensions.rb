module Trusty
  module Rails
    module ControllerExtensions
      
      # make sure Flash messages are preserved on redirect
      def redirect_to(*args)
        flash.keep
        super
      end
      
    end
  end
end