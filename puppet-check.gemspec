Gem::Specification.new do |spec|
  spec.name          = 'puppet-check'
  spec.version       = '0.9.0'
  spec.authors       = ['Matt Schuchard']
  spec.description   = 'Puppet Check is a gem that provides a comprehensive, streamlined, and efficient analysis of the syntax and style of your entire Puppet catalog.'
  spec.summary       = 'A streamlined comprehensive set of checks for your entire Puppet catalog'
  spec.homepage      = 'https://www.github.com/mschuchard/puppet-check'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |file| File.basename(file) }
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = Dir['lib']

  spec.required_ruby_version = Gem::Requirement.new('>= 1.9.3')
  spec.add_dependency 'rubocop', '~> 0'
  spec.add_dependency 'rake', '>= 9', '< 13' # becomes standard in later versions of ruby
  # spec.add_dependency 'rspec', '~> 3.0'
  spec.add_dependency 'puppet', '>= 3.2', '< 5'
  spec.add_dependency 'puppet-lint', '~> 1.1'
  # spec.add_dependency 'rspec-puppet', '~> 2.0'
  # spec.add_dependency 'beaker.' '~> 2.0'
  spec.add_dependency 'spdx-licenses', '~> 1.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
