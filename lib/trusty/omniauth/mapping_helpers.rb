module Trusty
  module Omniauth
    module MappingHelpers
      def clean(value, *filters, &default_value)
        default_value ||= lambda{ nil }
        
        filters.each do |method_name|
          value = value.to_s.send(method_name)
        end
        
        value.blank? ? default_value.call : value
      end
    end
  end
end