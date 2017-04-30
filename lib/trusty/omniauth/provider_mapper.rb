require 'trusty/omniauth/mapping_helpers'
require 'trusty/omniauth/model_mapper'

module Trusty
  module Omniauth
    class ProviderMapper
      include MappingHelpers

      attr_reader :provider_name, :provider_attributes, :options
      attr_reader :provider_identity, :provider_user

      # provider_attributes = OmniAuth data
      # options =
      # - :user_model = User model
      # - :user_relation = Relation to create new User on (optional, to call #build method on)
      # - :user_attributes = Hash of attributes to merge into user_attributes
      # - :user_attributes_names = Array of attribute names to copy from Omniauth data (default: User.column_names)
      # - :user_required_criteria = Hash of criteria to use to find users, and also to merge into attributes
      # - :user_identifiers = Array of column names that identify a model uniquely with omniauth data
      # - :identity_model = Identity model
      # - :identity_attributes = Hash of attributes to merge into identity_attributes
      # - :identity_attribute_names = Array of attribute names to copy from Omniauth data (default: Identity.column_names)
      # - :identity_required_criteria = Hash of criteria to use to find identities, and also to merge into attributes
      # - :identity_identifiers = Array of column names that identify a model uniquely with omniauth data
      # - :skip_raw_info (default: false) = Boolean whether to exclude OmniAuth "extra" data in identity_attributes[:raw_info]
      # - :skip_nils (default: true) = Boolean whether to remove attributes with nil values
      def initialize(provider_attributes, options = {})
        @provider_attributes  = provider_attributes.with_indifferent_access
        @provider_name        = provider_attributes['provider']
        @options              = {
          :user_attributes      => {},
          :identity_attributes  => {},
          :skip_raw_info        => false,
          :skip_nils            => true
        }.merge(options)

        @provider_identity = ModelMapper.new(self,
          :model              => @options[:identity_model] || ::Identity,
          :relation           => @options[:identity_relation],
          :attributes         => @options[:identity_attributes],
          :attribute_names    => @options[:identity_attribute_names],
          :unique_identifiers => @options[:identity_identifiers] || [:provider, :uid],
          :required_criteria  => @options[:identity_required_criteria]
        )
        @provider_user = ModelMapper.new(self,
          :model              => @options[:user_model] || ::User,
          :relation           => @options[:user_relation],
          :attributes         => @options[:user_attributes],
          :attribute_names    => @options[:user_attribute_names],
          :unique_identifiers => @options[:user_identifiers] || [:email],
          :required_criteria  => @options[:user_required_criteria]
        )
      end

      # Query existing

      def find_identities_for_user(user)
        @provider_identity.find_records(user_id: user.id)
      end

      # Matched identities based on omniauth unique identifiers (provider, uid)
      def matched_identities
        @matched_identities ||= @provider_identity.find_records
      end

      def identities_exist?
        matched_identities.any?
      end

      def single_identity?
        matched_identities.size == 1
      end

      def multiple_identities?
        matched_identities.size > 1
      end

      # Matched users based on omniauth unique identifiers (email)
      def matched_users
        @matched_users ||= @provider_user.find_records
      end

      def users_exist?
        matched_users.any?
      end

      def single_user?
        matched_users.size == 1
      end

      def multiple_users?
        matched_users.size > 1
      end

      def single_user
        @single_user ||= matched_users.first if single_user?
      end

      def single_identity
        @single_identity ||= matched_identities.first if single_identity?
      end

      # USER

      # Option :relation - pass in relation to build Identity from
      def build_user(attributes = {}, options = {})
        @provider_user.build_record(attributes, options)
      end

      # IDENTITY

      # Option :relation - pass in relation to build Identity from
      def build_identity(attributes = {}, options = {})
        @provider_identity.build_record(attributes, options)
      end

      def update_identity!(identity)
        @provider_identity.update_record!(identity)
      end

      ###### General ######

      def attributes(*filter_attribute_names)
        unless @attributes
          info            = provider_attributes.fetch('info', {})
          credentials     = provider_attributes['credentials']

          name            = clean(info['name'])       { [info['first_name'], info['last_name']].join(" ").strip }
          first_name      = clean(info['first_name']) { name.split(/\s+/, 2).first }
          last_name       = clean(info['last_name'])  { name.split(/\s+/, 2).last }

          @attributes = {
            :provider       => provider_name,
            :uid            => clean(provider_attributes['uid']),
            :name           => name,
            :email          => clean(info['email'], :downcase, :strip),
            :verified       => provider_attributes['extra']['raw_info']['verified_email'] == true,
            :username       => clean(info['nickname']),
            :first_name     => first_name,
            :middle_name    => clean(info['middle_name']),
            :last_name      => last_name,
            :phone          => clean(info['phone']),
            :image_url      => info['image'],
            :profile_url    => info.fetch('urls', {})['public_profile'],
            :token_type     => clean(credentials['token_type']),
            :token          => clean(credentials['token']),
            :secret         => clean(credentials['secret']),
            :refresh_token  => clean(credentials['refresh_token']),
            :expires        => credentials['expires'] == true,
            :expires_at     => (Time.at(credentials['expires_at']) rescue nil),
            :raw_info       => provider_attributes['extra'].except('access_token').as_json,
            # extra
            :location       => info['location'],
            :time_zone      => info['time_zone'] || Time.zone.name,
            :locale         => info['locale'] || I18n.locale
          }.with_indifferent_access

          @attributes.reject!{|_,value| value.nil?} if options[:skip_nils]
          @attributes.delete(:raw_info) if options[:skip_raw_info]
        end

        if filter_attribute_names.any?
          @attributes.slice(*filter_attribute_names)
        else
          @attributes.dup
        end
      end

    end
  end
end
