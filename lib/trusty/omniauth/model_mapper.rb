require 'trusty/omniauth/mapping_helpers'

module Trusty
  module Omniauth
    class ModelMapper
      include MappingHelpers

      attr_reader :unique_identifiers, :required_criteria

      def initialize(provider, options = {})
        @provider = provider
        @options  = options

        @unique_identifiers = @options.fetch(:unique_identifiers, []).map(&:to_s)
        @required_criteria  = stringify_keys @options.fetch(:required_criteria, {})
      end

      def model
        @options[:model]
      end

      def attribute_names
        # Remove required_criteria so that existing attributes are skipped
        @attribute_names ||= (@options[:attribute_names] || column_names).map(&:to_s) - required_criteria.keys
      end

      def attributes(*filter_attribute_names)
        @attributes ||= @provider.attributes(*attribute_names).merge(stringify_keys @options[:attributes]).merge(required_criteria)

        if filter_attribute_names.any?
          @attributes.slice(*filter_attribute_names)
        else
          @attributes.dup
        end
      end

      def build_record(additional_attributes = {})
        model.new(attributes.merge(required_criteria).merge(additional_attributes), without_protection: true)
      end

      def find_records(additional_criteria = {})
        unique_identifier_attributes = attributes(*unique_identifiers)
        empty_attributes = unique_identifiers - unique_identifier_attributes.keys

        raise "Missing unique attribute: #{empty_attributes.join(', ')}" if empty_attributes.any?

        conditions = model.where( unique_identifier_attributes )
        conditions = conditions.where(additional_criteria) unless additional_criteria.empty?
        conditions.where(required_criteria)
      end

      def update_record!(record)
        if Rails::VERSION::MAJOR >= 4
          record.update_attributes!(attributes)
        else
          record.update_attributes!(attributes, without_protection: true)
        end
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

      protected
        def stringify_keys(original_hash)
          original_hash.each_with_object({}){|(key, value), hash| hash[key.to_s] = value}
        end
    end
  end
end
