require 'rspec'

# for path to fixtures
FIXTURES_DIR = "#{File.dirname(__FILE__)}/fixtures/".freeze
OCTOCATALOG_DIFF_DIR = "#{File.dirname(__FILE__)}/octocatalog-diff/".freeze
CI_ENV = ENV['CIRCLECI'] == 'true' || ENV['GITHUB_ACTIONS'] == 'true'

RSpec.configure do |config|
  config.color = true
end
