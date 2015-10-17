require 'trusty/omniauth/mapping_helpers'

module Trusty
  module Omniauth
    class ModelMapper
      include MappingHelpers
      
      def initialize(provider, options = {})
        @provider = provider
        @options  = options
      end
      
      def model
        @options[:model]
      end
      
      def attribute_names
        @attribute_names ||= @options[:attribute_names] || column_names
      end
      
      def attributes(*filter_attribute_names)
        @attributes ||= @provider.attributes(*attribute_names).merge!(@options[:attributes])
        
        if filter_attribute_names.any?
          @attributes.slice(*filter_attribute_names)
        else
          @attributes.dup
        end
      end
      
      def build_record(additional_attributes = {})
        model.new(attributes.merge(additional_attributes), without_protection: true)
      end
      
      def update_record!(record)
        record.update_attributes!(attributes, :without_protection => true)
      end
      
      def column_names
        @column_names ||= if model.respond_to? :column_names
          model.column_names.map(&:to_sym)
        elsif model.respond_to? :fields
          model.fields.map{|c| c[1].name.to_sym}
        else
          []
        end
      end
    end
  end
end