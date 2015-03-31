# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name                  = 'guard-bosh'
  spec.version               = '0.1.0'
  spec.authors               = ['Andrew Crump']
  spec.email                 = ['andrew@cloudcredo.com']
  spec.summary               = 'Fast feedback when developing BOSH releases'
  spec.homepage              = 'https://github.com/cloudcredo/guard-bosh'
  spec.license               = 'Apache 2'
  spec.required_ruby_version = '>= 2.0'
  spec.files                 = Dir.glob('{lib,spec}/**/*')
  spec.require_path          = 'lib'

  spec.add_dependency 'bosh-template', '~> 1.2889'
  spec.add_dependency 'deep_merge', '~> 1.0'
  spec.add_dependency 'guard-compat', '~> 1.2'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'guard-rspec', '~> 4.5'
  spec.add_development_dependency 'rake', '~> 10.4'
  spec.add_development_dependency 'simplecov', '~> 0.9'
end
