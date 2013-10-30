# Trusty

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'trusty'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install trusty

## Usage

Trusty is a library of a bunch of useful utilities.

### Environment Variables

Use `Trusty::Environment` (or the shorthand `Vars`) to access environment variables. 
What's handy is that it will load up environment variables from a `env.yml` file and merge it with `ENV`. 
By default, it loads the section of the YAML file based on the current `ENV['RAILS_ENV']` and `ENV['RACK_ENV']`. 
You can customize the section to load by setting `ENV['ENV_SECTION']` to a custom name.

```Ruby
# See what the default section name is that will be pulled from env.yml
section_name = Vars.default_env_section

# The following are equivalent
api_key = Vars['API_KEY']
api_key = Vars.env['API_KEY']
api_key = Vars.env.api_key

# You can load any YAML file into a Vars property dynamically (should return a Hash).
# Files will be loaded from Rails' "config" directory by default. These are equivalent:
custom_config = Vars.custom_config # loads config/custom_config.yml as a Hashie::Mash
custom_config = Vars.config.custom_config

# add paths to find YAML files in other locations (especially if not using Rails)
paths = [
  Rails.root.join('config'),        # added by default
  Rails.root,                       # search in the root
  Rails.root.join('custom', 'folder') # look in custom/folder/* inside Rails app
]

Vars.paths += paths

# This will find the another_config.yml file under the custom path
another_config = Vars.another_config # loads custom/folder/another_config.yml as a Hashie::Mash
another_config = Vars.config.another_config

# To access a list of all YAML files that have been loaded
hash_of_configs = Vars.config
```

### Omniauth

To easily map Omniauth data to your `User` and/or `Idenity` models with a `User#identities` relationship, use the `Trusty::Omniauth::ProviderMapper` class. Both ActiveRecord and Mongoid are supported.

Add this line to your application's Gemfile:

    gem 'trusty', require: 'trusty/omniauth'

Just pass in the Omniauth `Hash` provided in the environment variable to the [`ProviderMapper`](lib/trusty/omniauth/provider_mapper.rb) and you can use the helper methods to populate your models. Check out  for more options.

```Ruby
omniauth = request.env['omniauth.auth']

# these are some default options that you can override
options = {
  user_model: User,
  user_attributes_names: User.column_names,
  identity_model: Identity,
  identity_attribute_names: Identity.column_names
}

# Here is a class that you can use to deal with your model instances, 
# whether finding a user based on their identity or adding a new identity to a user, 
# or even creating a new user with the identity.
mapper = Trusty::Omniauth::ProviderMapper.new(omniauth, options)
```

### YAML

Use `Trusty::Utilities::Yaml` to load a file or content. 
An instance of `Trusty::Utilities::YamlContext` is used for rendering YAML and is used as the context. 
If you pass a block to the method where you pass in the file or content, you can include modules and so on in the context if necessary.

```Ruby
# load a file
relative_path = "yaml/filename.yml"

# optional: pass in an array of paths where to search for the file
optional_paths = [ Rails.root, Rails.root.join('config') ]

# Render YAML and any ERB blocks
result = Trusty::Utilities::Yaml.load_file(relative_path, optional_paths) do |context|
  # optionally use a block to modify the context (YamlContext instance)
end
```

You can use `YamlContext` directly:

```Ruby
# load the content from the file
content = File.read Trusty::Utilities::PathFinder.find(relative_path, optional_paths)

# render the YAML as a Ruby object
result = Trusty::Utilities::YamlContext.render content do |context|
  # optionally use a block to modify the context (YamlContext instance)
end
```

### `method_missing` Helpers

If you want to dynamically add boolean methods to a class, use `Trusty::Utilities::MethodName`. 
It will allow you to return a boolean for a method that ends with '?'. 
It will also dynamically define the methods for you with a simple module to extend your class called `Trusty::Utilities::MethodNameExtensions`. 

If you want more control over what happens in your `method_missing` method, you can use [`MethodName`](lib/trusty/utilities/method_name.rb) instances to give you information about the method name you are handling.

```Ruby
target      = MyModel.new
method_name = "confirmed_at?"

# get info about the method name inside method_missing
method_info = Trusty::Utilities::MethodName.new(method_name)

# see if it's a boolean method
method_info.boolean? # true

# if you want to see what the value is for the method name without the '?'
method_name.base_value_for target # "2013-10-30 19:41:40 UTC"

# get the boolean value
method_name.method_value_for target # true

# define the helper method on the target (if it isn't already on there)
method_name.define_for target # true
```

Make this functionality automatic by including the `Trusty::Utilities::MethodNameExtensions` module in your class.

```Ruby
class MyModel
  include Trusty::Utilities::MethodNameExtensions
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
