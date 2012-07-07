# -*- encoding: utf-8 -*-
require File.expand_path('../lib/endpoint/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Adam Williams']
  gem.email         = ['adam@thewilliams.ws']
  gem.description   = %q{Provides for connecting to API endpoints.}
  gem.summary       = %q{Provides for connecting to API endpoints.}
  gem.homepage      = ''

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'endpoint'
  gem.require_paths = ['lib']
  gem.version       = Endpoint::VERSION

  gem.add_runtime_dependency 'nokogiri', '>= 1.5', '< 2.0'
  gem.add_runtime_dependency 'nori', '>= 1.1', '< 1.2'
  gem.add_runtime_dependency 'httparty', '>= 0.8.3', '< 2.0'
  gem.add_runtime_dependency 'socksify', '>= 1.4', '< 2.0'

  gem.add_development_dependency 'rspec-core'
  gem.add_development_dependency 'rspec-expectations'
  gem.add_development_dependency 'rspec-mocks'
  gem.add_development_dependency 'webmock'
end
