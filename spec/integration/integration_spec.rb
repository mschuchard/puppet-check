require_relative '../spec_helper.rb'
require_relative '../../lib/puppet-check/cli'

# TODO: RC
describe 'PuppetCheck' do
  let(:puppet_check) { PuppetCheck.new }

  context 'executed as a system from the CLI with various files to be processed' do
    it 'outputs diagnostic results correctly after processing all of the files' do
      PuppetCheck::CLI.run(%W(-s --puppet-lint no-hard_tabs-check,no-80chars-check --rubocop Metrics/LineLength,Style/Encoding #{fixtures_dir}))
    end
  end

  context 'executed as a system from the Rakefile with various files to be processed' do
    it 'outputs diagnostic results correctly after processing all of the files' do
      #
    end
  end
end
