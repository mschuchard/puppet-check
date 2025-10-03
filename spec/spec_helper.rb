require 'rspec'

# for path to fixtures
module Variables
  extend RSpec::SharedContext

  def fixtures_dir
    @fixtures_dir = "#{File.dirname(__FILE__)}/fixtures/"
  end

  def octocatalog_diff_dir
    @octocatalog_diff_dir = "#{File.dirname(__FILE__)}/octocatalog-diff/"
  end

  def ci_env
    @ci_env = ENV['CIRCLECI'] == 'true' || ENV['GITHUB_ACTIONS'] == 'true'
  end
end

RSpec.configure do |config|
  config.include Variables
  config.color = true
end
