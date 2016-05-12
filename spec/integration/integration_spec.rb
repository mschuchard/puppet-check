require 'rake'
require_relative '../spec_helper.rb'
require_relative '../../lib/puppet-check/cli'
require_relative '../../lib/puppet-check/tasks'

describe 'PuppetCheck' do
  context 'executed as a system from the CLI with arguments and various files to be processed' do
    let(:cli) { PuppetCheck::CLI.run(%W(-s --puppet-lint no-hard_tabs-check,no-80chars-check --rubocop Metrics/LineLength,Style/Encoding #{fixtures_dir})) }

    it 'outputs diagnostic results correctly after processing all of the files' do
      expect(cli).to eql(0)
      expect(PuppetCheck.error_files.length).to eql(8)
      expect(PuppetCheck.warning_files.length).to eql(8)
      expect(PuppetCheck.clean_files.length).to eql(9)
      expect(PuppetCheck.ignored_files.length).to eql(1)
    end
  end

  context 'executed as a system from the Rakefile with arguments and various files to be processed' do
    # let(:tasks) { PuppetCheck::Tasks.new }
    before(:each) do
      FileUtils.cd fixtures_dir
      PuppetCheck.error_files = []
      PuppetCheck.warning_files = []
      PuppetCheck.clean_files = []
      PuppetCheck.ignored_files = []
      PuppetCheck.style_check = true
    end

    it 'outputs diagnostic results correctly after processing all of the files' do
      expect { Rake::Task['puppetcheck:file'].invoke }.not_to raise_exception
      expect(PuppetCheck.error_files.length).to eql(8)
      expect(PuppetCheck.warning_files.length).to eql(8)
      expect(PuppetCheck.clean_files.length).to eql(9)
      expect(PuppetCheck.ignored_files.length).to eql(1)
    end
  end
end
