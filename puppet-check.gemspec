Gem::Specification.new do |spec|
  spec.name          = 'puppet-check'
  spec.version       = 'Alpha'
  spec.authors       = ['Matt Schuchard']
  spec.description   = 'A streamlined comprehensive set of checks for your entire Puppet catalog'
  spec.summary       = 'A streamlined comprehensive set of checks for your entire Puppet catalog'
  spec.homepage      = 'https://www.github.com/mschuchard/puppet-check'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |file| File.basename(file) }
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = Dir['lib']

  spec.required_ruby_version = Gem::Requirement.new('>= 1.9.3')
  spec.add_dependency 'rubocop'
  # spec.add_dependency 'rspec'
  spec.add_runtime_dependency 'puppet', '>= 3.2'
  spec.add_runtime_dependency 'puppet-lint', '>= 1.1.0'
  sped.add_runtime_dependency 'yaml'
  spec.add_runtime_dependency 'json'
  # spec.add_runtime_dependency 'rspec-puppet'
  # spec.add_runtime_dependency 'beaker'
  spec.add_runtime_dependency 'metadata-json-lint'
  spec.add_development_dependency 'rspec', '>= 3.0'
end
