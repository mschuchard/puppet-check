Gem::Specification.new do |spec|
  spec.name          = 'puppet-check'
  spec.version       = '1.5.1'
  spec.authors       = ['Matt Schuchard']
  spec.description   = 'Puppet Check is a gem that provides a comprehensive, streamlined, and efficient analysis of the syntax, style, and validity of your entire Puppet code and data.'
  spec.summary       = 'A streamlined comprehensive set of checks for your entire Puppet code and data'
  spec.homepage      = 'https://www.github.com/mschuchard/puppet-check'
  spec.license       = 'MIT'

  spec.files         = Dir['bin/**/*', 'lib/**/*', 'spec/**/*', 'CHANGELOG.md', 'LICENSE.md', 'README.md']
  spec.executables   = spec.files.grep(%r{^bin/}) { |file| File.basename(file) }
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = Dir['lib']

  spec.required_ruby_version = '>= 2.0.0'
  spec.add_dependency 'puppet', '>= 3.4', '< 6'
  spec.add_dependency 'puppet-lint', '>= 1.1.0', '< 3'
  spec.add_dependency 'rubocop', '~> 0'
  spec.add_dependency 'spdx-licenses', '~> 1.0'
  spec.add_development_dependency 'octocatalog-diff', '~> 1.0'
  spec.add_development_dependency 'rake', '>= 9', '< 13'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
