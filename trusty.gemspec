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

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  
  # Trusty::Rails (and defined?(Rails) checks sprinkled throughout)
  spec.add_development_dependency "rails"
  
  # Trusty::Omniauth
  spec.add_development_dependency "omniauth"
  
  # Trusty::Errors::ExceptionHandlers
  spec.add_development_dependency "active_support" # active_support/notifications
  
  # Trusty::ExceptionNotification
  spec.add_development_dependency "exception_notification"
  
  # Trusty::Rake
  spec.add_development_dependency "rake"
  
  # Trusty::IronIo::QueueProcessor
  spec.add_development_dependency "typhoeus" # used by iron_mq
  spec.add_development_dependency "iron_mq"
  
  # Trusty::Environment
  spec.add_dependency "dotenv", ">= 0.9.0"
  spec.add_dependency "hashie", ">= 2.0"
end
