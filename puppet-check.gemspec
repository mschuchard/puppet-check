Gem::Specification.new do |spec|
  spec.name          = 'puppet-check'
  spec.version       = '2.4.0'
  spec.authors       = ['Matt Schuchard']
  spec.description   = 'Puppet Check is a gem that provides a comprehensive, streamlined, and efficient analysis of the syntax, style, and validity of your entire Puppet code and data.'
  spec.summary       = 'A streamlined comprehensive set of checks for your entire Puppet code and data'
  spec.homepage      = 'https://www.github.com/mschuchard/puppet-check'
  spec.license       = 'MIT'

  spec.files         = Dir['bin/**/*', 'lib/**/*', 'spec/**/*', 'CHANGELOG.md', 'LICENSE.md', 'README.md', 'puppet-check.gemspec']
  spec.executables   = spec.files.grep(%r{^bin/}) { |file| File.basename(file) }
  spec.require_paths = Dir['lib']

  spec.required_ruby_version = '>= 3.1.0'
  spec.add_dependency 'puppet', '>= 5.5', '< 9'
  spec.add_dependency 'puppet-lint', '~> 5.0'
  spec.add_dependency 'reek', '~> 6.0'
  spec.add_dependency 'rubocop', '~> 1.72'
  spec.add_dependency 'rubocop-performance', '~> 1.0'
  spec.add_dependency 'rubocop-rspec', '~> 3.0'
  # spec.add_development_dependency 'octocatalog-diff', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
