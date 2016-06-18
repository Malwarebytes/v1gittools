# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'v1gittools/version'

Gem::Specification.new do |spec|
  spec.name          = 'v1gittools'
  spec.version       = V1gittools::VERSION
  spec.authors       = ['Jonathan Chan']
  spec.email         = ['jchan@malwarebytes.org']

  spec.summary       = %q{Random V1 Tools}
  spec.description   = %q{1st Tool, v1 -> git changelog creator}
  spec.homepage      = 'http://malwarebytes.org'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'git', '~> 1.3.0'
  spec.add_runtime_dependency 'versionone_sdk', '~>0.2'
  spec.add_runtime_dependency 'thor', '~> 0.19'
  spec.add_runtime_dependency 'launchy', '~> 2.4', '>= 2.4.3'

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
