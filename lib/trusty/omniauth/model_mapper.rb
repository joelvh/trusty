require 'trusty/omniauth/mapping_helpers'

module Trusty
  module Omniauth
    class ModelMapper
      include MappingHelpers

      attr_reader :model, :relation, :column_names, :unique_identifiers, :required_criteria

      def initialize(provider, options = {})
        @provider = provider
        @options  = options.dup

        @model, @relation, @column_names = extract_orm_components(@options)

        @unique_identifiers = @options.fetch(:unique_identifiers, []).map(&:to_s)
        @required_criteria  = stringify_keys @options.fetch(:required_criteria, {})
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

      def build_record(additional_attributes = {}, options = {})
        build_relation = (options[:relation] || relation)
        build_relation.build(attributes.merge(required_criteria).merge(additional_attributes))
      end

      def find_records(additional_criteria = {})
        unique_identifier_attributes = attributes(*unique_identifiers)
        empty_attributes = unique_identifiers - unique_identifier_attributes.keys

        raise "Missing unique attribute: #{empty_attributes.join(', ')}" if empty_attributes.any?

        conditions = relation.where( unique_identifier_attributes )
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

    protected

      def extract_orm_components(options)
        prepared_model    = options[:model]
        prepared_relation = options[:relation]

        prepared_model ||=  if prepared_relation.respond_to? :model
                              # ActiveRecord
                              prepared_relation.model
                            elsif prepared_relation.respond_to? :metadata
                              # Mongoid
                              prepared_relation.metadata.klass
                            else
                              prepared_model
                            end

        prepared_relation ||= if prepared_model.respond_to? :default_scoped
                                # ActiveRecord
                                prepared_model.default_scoped
                              elsif prepared_model.respond_to? :default_scope
                                # Mongoid
                                prepared_model.default_scope
                              else
                                prepared_relation
                              end

        prepared_column_names = if prepared_model.respond_to? :column_names
                                  # ActiveRecord
                                  prepared_model.column_names.map(&:to_sym)
                                elsif prepared_model.respond_to? :attribute_names
                                  # ActiveModel and Mongoid
                                  prepared_model.attribute_names.map(&:to_sym)
                                elsif prepared_model.respond_to? :fields
                                  # Older Mongoid
                                  prepared_model.fields.map{|c| c[1].name.to_sym}
                                else
                                  []
                                end

        [prepared_model, prepared_relation, prepared_column_names]
      end

      def stringify_keys(original_hash)
        original_hash.each_with_object({}){|(key, value), hash| hash[key.to_s] = value}
      end
    end
  end
end
