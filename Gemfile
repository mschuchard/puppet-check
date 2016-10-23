source 'https://rubygems.org'

gemspec

# reek 4.x requires ruby >=  2.1
if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.1.0')
  gem 'reek', '~> 4.0'
# reek 3.11 was the last to support ruby 2.0
else
  gem 'reek', '3.11'
end
