require 'rake/task'
require_relative '../spec_helper.rb'
require_relative '../../lib/puppet-check/cli'
require_relative '../../lib/puppet-check/tasks'

describe PuppetCheck do
  context 'executed as a system from the CLI with arguments and various files to be processed' do
    # see regression_check_spec
    if File.directory?('/home/travis')
      let(:cli) { PuppetCheck::CLI.run(%w(-s --puppet-lint no-hard_tabs-check,no-140chars-check --rubocop Metrics/LineLength,Style/Encoding .)) }
    else
      let(:cli) { PuppetCheck::CLI.run(%w(-s --puppet-lint no-hard_tabs-check,no-140chars-check --rubocop Metrics/LineLength,Style/Encoding --smoke -n good.example.com --octoconfig spec/octocatalog-diff/octocatalog-diff.cfg.rb .)) }
    end

    it 'outputs diagnostic results correctly after processing all of the files' do
      Dir.chdir(fixtures_dir)

      expect { cli }.not_to raise_exception

      expect(PuppetCheck.error_files.length).to eql(8)
      # stupid Puppet deprecation warning
      if RUBY_VERSION.to_f < 2.1
        expect(PuppetCheck.warning_files.length).to eql(10)
        expect(PuppetCheck.clean_files.length).to eql(10)
      else
        expect(PuppetCheck.warning_files.length).to eql(9)
        expect(PuppetCheck.clean_files.length).to eql(11)
      end
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
      # see regression_check_spec
      unless File.directory?('/home/travis')
        PuppetCheck.smoke_check = true
        PuppetCheck.octonodes = %w(good.example.com)
        PuppetCheck.octoconfig = 'spec/octocatalog-diff/octocatalog-diff.cfg.rb'
      end

      expect { tasks }.not_to raise_exception

      expect(PuppetCheck.error_files.length).to eql(8)
      expect(PuppetCheck.warning_files.length).to eql(9)
      expect(PuppetCheck.clean_files.length).to eql(11)
      expect(PuppetCheck.ignored_files.length).to eql(1)
    end
  end
end
