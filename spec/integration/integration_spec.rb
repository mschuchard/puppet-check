require 'rake'
require_relative '../spec_helper.rb'
require_relative '../../lib/puppet-check/cli'
require_relative '../../lib/puppet-check/tasks'

describe 'PuppetCheck' do
  context 'executed as a system from the CLI with arguments and various files to be processed' do
    let(:cli) { PuppetCheck::CLI.run(%W(-s --puppet-lint no-hard_tabs-check,no-80chars-check --rubocop Metrics/LineLength,Style/Encoding #{fixtures_dir})) }

    it 'outputs diagnostic results correctly after processing all of the files' do
      expect(cli).to eql(0)
    end
  end

  context 'executed as a system from the Rakefile with arguments and various files to be processed' do
    let(:tasks) { PuppetCheck::Tasks.new }
    before(:each) do
      FileUtils.cd fixtures_dir
      PuppetCheck.error_files = []
      PuppetCheck.warning_files = []
      PuppetCheck.clean_files = []
      PuppetCheck.ignored_files = []
      PuppetCheck.style_check = false
    end

    it 'outputs diagnostic results correctly after processing all of the files' do
      expect { Rake::Task['puppetcheck:all'].invoke }.not_to raise_exception
    end
  end
end
