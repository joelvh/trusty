require_relative "utilities"
require_relative "environment/dot_file_parser"

module Trusty
  module Environment
    module ClassMethods
      include Utilities::MethodNameExtensions
      
      # load env.yml into ENV (e.g. ENV['DATABASE_URL'])
      def load_env!(options = {})
        source = load_yaml_file("env.yml")
        source = source.fetch(options[:env_section] || env_section, {})
        
        source.each do |key, value|
          if !ENV.has_key?(key) || options[:overwrite] == true
            ENV[key.to_s.upcase] = value.to_s
          end
        end
      end
      
      # load env.yml into constants (e.g. Vars::DATABASE_URL)
      def load_constants!(options = {})
        source = load_yaml_file("env.yml")
        source = source.fetch(options[:env_section] || env_section, {})
        
        source.each do |key, value|
          constant_name = key.to_s.upcase.to_sym
          
          if !constants.include(constant_name) || options[:overwrite] == true
            constant_set constant_name, value.to_s
          end
        end
      end
      
      def [](key)
        env[key.to_s.downcase]
      end
      
      # downcases keys to method names
      def env(env_section = default_env_section)
        @env ||= {}
        @env[env_section] ||= methodize_hash env_source(env_section).merge(ENV.to_hash)
      end
      
      def env_source(env_section = default_env_section)
        @env_source ||= {}
        @env_source[env_section] ||= load_yaml_file("env.yml").fetch(env_section, {})
      end
      
      def default_env_section
        @default_env_section ||= ENV['ENV_SECTION'] || ENV['RAILS_ENV'] || ENV['RACK_ENV']
      end
      
      def config(default_value = nil)
        # loads YAML on-the-fly when a key doesn't exist
        @config ||= Hashie::Mash.new do |hash, key|
          hash[key] = methodize_hash load_yaml_file("#{key}.yml", default_value)
        end
      end
      
      def paths
        @paths ||= defined?(Rails) ? [ Rails.root.join("config").to_s ] : []
      end
      
      # dynamically add methods that forward to config
      def method_missing(name, *args, &block)
        if !method_name_info(name).special?
          instance_variable_name  = :"@#{name}"
          instance_variable_value = config[name]
          instance_variable_set instance_variable_name, instance_variable_value
          
          define_singleton_method name do
            instance_variable_get instance_variable_name
          end
          
          instance_variable_value
        else
          super
        end
      end
      
      private
      
      def load_yaml_file(filename, default_value = {})
        Utilities::Yaml.load_file(filename, paths) || default_value
      end
      
      def methodize_hash(hash)
        if hash != nil
          Hashie::Mash.new hash.inject({}){|result, (key, value)| result.merge(key.underscore.downcase => value)}
        end
      end
      
    end
    
    # create class methods
    extend ClassMethods
  end
end

# copy out of namespace
Vars = Trusty::Environment
