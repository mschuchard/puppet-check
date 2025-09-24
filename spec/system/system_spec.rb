require 'rake/task'
require_relative '../spec_helper'
require_relative '../../lib/puppet-check/cli'
require_relative '../../lib/puppet-check/tasks'

describe PuppetCheck do
  context 'executed as a system from the CLI with arguments and various files to be processed' do
    # see regression_check_spec
    if ENV['CIRCLECI'] == 'true' || ENV['GITHUB_ACTIONS'] == 'true'
      let(:cli) { PuppetCheck::CLI.run(%w[-s --puppet-lint no-hard_tabs-check,no-140chars-check --rubocop Layout/LineLength,Style/Encoding --public keys/public_key.pkcs7.pem --private keys/private_key.pkcs7.pem .]) }
    else
      let(:cli) { PuppetCheck::CLI.run(%w[-s --puppet-lint no-hard_tabs-check,no-140chars-check --rubocop Layout/LineLength,Style/Encoding --public keys/public_key.pkcs7.pem --private keys/private_key.pkcs7.pem --smoke -n good.example.com --octoconfig spec/octocatalog-diff/octocatalog-diff.cfg.rb .]) }
    end

    it 'outputs diagnostic results correctly after processing all of the files' do
      Dir.chdir(fixtures_dir)

      expect { cli }.not_to raise_exception

      expect(PuppetCheck.files[:errors].length).to eql(11)
      expect(PuppetCheck.files[:warnings].length).to eql(12)
      expect(PuppetCheck.files[:clean].length).to eql(14)
      expect(PuppetCheck.files[:ignored].length).to eql(3)

      expect(cli).to eql(2)
    end
  end

  context 'executed as a system from the Rakefile with arguments and various files to be processed' do
    it 'outputs diagnostic results correctly after processing all of the files' do
      # ensure rake only checks the files inside fixtures
      Dir.chdir(fixtures_dir)

      # clear out files member from previous system test
      PuppetCheck.files = {
        errors: {},
        warnings: {},
        clean: [],
        ignored: []
      }

      # cannot re-use plan fixture between system tests
      expect { Rake::Task[:'puppetcheck:file'].invoke() }.to raise_error(ArgumentError, /Attempt to redefine entity/)

      # current puppet pops limitations no longer allow testing this
      # expect(PuppetCheck.files[:errors].length).to eql(11)
      # expect(PuppetCheck.files[:warnings].length).to eql(12)
      # expect(PuppetCheck.files[:clean].length).to eql(14)
      # expect(PuppetCheck.files[:ignored].length).to eql(3)
    end

    it 'uses override settings and outputs diagnostic results correctly after processing all of the files' do
        # ensure rake only checks the files inside fixtures
        Dir.chdir(fixtures_dir)

        # clear out files member from previous system test
        PuppetCheck.files = {
          errors: {},
          warnings: {},
          clean: [],
          ignored: []
        }

        # assign settings
        settings = { style: true }
        # see regression_check_spec
        unless ENV['CIRCLECI'] == 'true' || ENV['GITHUB_ACTIONS'] == 'true'
          settings[:smoke] = true
          settings[:octonodes] = %w[good.example.com]
          settings[:octoconfig] = 'spec/octocatalog-diff/octocatalog-diff.cfg.rb'
        end

        # cannot re-use plan fixture between system tests
        expect { Rake::Task[:'puppetcheck:file'].invoke(settings) }.to raise_error(ArgumentError, /Attempt to redefine entity/)

        # current puppet pops limitations no longer allow testing this
        # expect(PuppetCheck.files[:errors].length).to eql(11)
        # expect(PuppetCheck.files[:warnings].length).to eql(12)
        # expect(PuppetCheck.files[:clean].length).to eql(14)
        # expect(PuppetCheck.files[:ignored].length).to eql(3)
    end
  end
end
