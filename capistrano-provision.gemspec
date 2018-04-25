# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "capistrano-provision"
  gem.version       = '0.1.0'
  gem.authors       = ["keegnotrub"]
  gem.description   = %q{Provision Ubunut 16.04 LTS server(s) with Capistrano}
  gem.summary       = %q{Provision Ubunut 16.04 LTS server(s) with Capistrano}
  gem.homepage      = "https://github.com/keegnotrub/capistrano-provision"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'capistrano', '~> 3.1'
  gem.add_dependency 'capistrano-chruby', '~> 0.1'
  gem.add_dependency 'capistrano-bundler', '~> 1.1'
  gem.add_dependency 'capistrano-rails', '~> 1.1'
end
