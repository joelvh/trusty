# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trusty/version'

Gem::Specification.new do |spec|
  spec.name          = "trusty"
  spec.version       = Trusty::VERSION
  spec.authors       = ["Joel Van Horn"]
  spec.email         = ["joel@joelvanhorn.com"]
  spec.description   = %q{Trusty is a configuration and utilities library.}
  spec.summary       = %q{Trusty allows you to manage environment variables and other common configuration challenges.}
  spec.homepage      = "https://github.com/joelvh/trusty"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.3"
  
  # Trusty::Rails (and defined?(Rails) checks sprinkled throughout)
  spec.add_development_dependency "rails", ">= 3"
  
  # Trusty::Omniauth
  spec.add_development_dependency "omniauth", "~> 2"
  
  # Trusty::Errors::ExceptionHandlers
  spec.add_development_dependency "activesupport", ">= 3" # active_support/notifications
  
  # Trusty::ExceptionNotification
  spec.add_development_dependency "exception_notification", ">= 3"
  
  # Trusty::Rake
  spec.add_development_dependency "rake", ">= 9"
  
  # Trusty::IronIo::QueueProcessor
  spec.add_development_dependency "typhoeus", ">= 0.8" # used by iron_mq
  spec.add_development_dependency "iron_mq"
  
  # Trusty::Environment
  spec.add_dependency "dotenv", ">= 0.9.0"
  spec.add_dependency "hashie", ">= 2.0"
end
