source 'https://rubygems.org'

gemspec

# reek 4.x requires ruby >=  2.1
if RUBY_VERSION.to_f >= 2.1
  gem 'reek', '~> 4.0'
# reek 3.11 was the last to support ruby 2.0
else
  gem 'reek', '3.11'
end
