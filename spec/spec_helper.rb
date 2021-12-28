require 'rspec'

# for path to fixtures
module Variables
  extend RSpec::SharedContext

  let(:fixtures_dir) { "#{File.dirname(__FILE__)}/fixtures/" }
  let(:octocatalog_diff_dir) { "#{File.dirname(__FILE__)}/octocatalog-diff/" }
end

RSpec.configure do |config|
  config.include Variables
  config.color = true
end
