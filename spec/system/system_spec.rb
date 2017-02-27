require 'rake/task'
require_relative '../spec_helper.rb'
require_relative '../../lib/puppet-check/cli'
require_relative '../../lib/puppet-check/tasks'

describe PuppetCheck do
  context 'executed as a system from the CLI with arguments and various files to be processed' do
    let(:cli) { PuppetCheck::CLI.run(%w(-s --puppet-lint no-hard_tabs-check,no-140chars-check --rubocop Metrics/LineLength,Style/Encoding .)) }

    it 'outputs diagnostic results correctly after processing all of the files' do
      Dir.chdir(fixtures_dir)

      expect { cli }.not_to raise_exception

      expect(PuppetCheck.error_files.length).to eql(9)
      expect(PuppetCheck.warning_files.length).to eql(10)
      expect(PuppetCheck.clean_files.length).to eql(11)
      expect(PuppetCheck.ignored_files.length).to eql(1)

      expect(cli).to eql(2)
    end
  end

  context 'executed as a system from the Rakefile with arguments and various files to be processed' do
    let(:tasks) { Rake::Task['puppetcheck:file'.to_sym].invoke }

    it 'outputs diagnostic results correctly after processing all of the files' do
      # ensure rake only checks the files inside fixtures
      Dir.chdir(fixtures_dir)

      # clear out arrays from previous system test
      PuppetCheck.error_files = []
      PuppetCheck.warning_files = []
      PuppetCheck.clean_files = []
      PuppetCheck.ignored_files = []
      PuppetCheck.style_check = true

      expect { tasks }.not_to raise_exception

      expect(PuppetCheck.error_files.length).to eql(9)
      expect(PuppetCheck.warning_files.length).to eql(10)
      expect(PuppetCheck.clean_files.length).to eql(11)
      expect(PuppetCheck.ignored_files.length).to eql(1)
    end
  end
end
