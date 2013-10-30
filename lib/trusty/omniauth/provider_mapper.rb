module Trusty
  module Omniauth
    class ProviderMapper
      include MappingHelpers
      
      attr_reader :provider_name, :provider_attributes, :options
      attr_reader :provider_identity, :provider_user
      
      # provider_attributes = OmniAuth data
      # options = 
      # - :user_model = User model
      # - :user_attributes = Hash of attributes to merge into user_attributes
      # - :user_attributes_names = Array of attribute names to copy from Omniauth data (default: User.column_names)
      # - :identity_model = Identity model
      # - :identity_attributes = Hash of attributes to merge into identity_attributes
      # - :identity_attribute_names = Array of attribute names to copy from Omniauth data (default: Identity.column_names)
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
          :model            => @options[:identity_model] || Identity,
          :attributes       => @options[:identity_attributes],
          :attribute_names  => @options[:identity_attribute_names]
        )
        @provider_user = ModelMapper.new(self,
          :model            => @options[:user_model] || User,
          :attributes       => @options[:user_attributes],
          :attribute_names  => @options[:user_attribute_names]
        )
      end
      
      # Query existing
      
      def user
        # first try to find the user based on provider/uid combo
        @user ||= find_user_by_identity
        # find the user by email if not found by identity
        @user ||= find_user_by_email
      end
      
      def identity
        @identity ||= find_identity_by_user
      end
      
      def user_exists?
        !user.nil?
      end
      
      def identity_exists?
        !identity.nil?
      end
      
      # USER
      
      def build_user
        @provider_user.build_record
      end
      
      # IDENTITY
      
      def build_identity
        @provider_identity.build_record
      end
      
      def build_identity_for_user(user)
        build_identity.tap do |identity|
          # this assumes there is an inverse relationship automatically created
          # such as user.identities would now contain this identity for the user
          identity.user = user
        end
      end
      
      def update_existing_identity!
        raise "Identity doesn't exist!" unless identity
        
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
            :token          => clean(credentials['token']),
            :secret         => clean(credentials['secret']),
            :refresh_token  => clean(credentials['refresh_token']),
            :expires        => credentials['expires'] == true,
            :expires_at     => (Time.at(credentials['expires_at']) rescue nil),
            :raw_info       => provider_attributes['extra'].except('access_token').as_json,
            # extra
            :time_zone      => Time.zone.name
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
      
      private
      
      def find_user_by_identity
        if defined?(Mongoid::Document) && @provider_user.model.include?(Mongoid::Document)
          @provider_user.model.elem_match(:identities => @provider_identity.attributes(:provider, :uid)).first
        else
          @provider_user.model.where(
            :id => @provider_identity.model.where( @provider_identity.attributes(:provider, :uid) ).select(:user_id)
          ).first
        end
      end
      
      def find_user_by_email
        @provider_user.model.where( @provider_identity.attributes(:email) ).first
      end
      
      def find_identity_by_user
        user && user.identities.where( @provider_identity.attributes(:provider, :uid) ).first
      end
      
    end
  end
end