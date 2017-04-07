require_relative '../spec_helper'
require_relative '../../lib/puppet-check/cli'

describe PuppetCheck::CLI do
  context '.run' do
    it 'raises an error if no paths were specified' do
      expect { PuppetCheck::CLI.run(%w(-s -f)) }.to raise_error(RuntimeError, 'puppet-check: no paths specified; try using --help')
    end
  end

  context '.parse' do
    it 'raises an error if an invalid option was specified' do
      expect { PuppetCheck::CLI.parse(%w(-s -f -asdf foo)) }.to raise_error(OptionParser::InvalidOption)
    end

    it 'allows future parser, style, smoke, and regression checks to be enabled' do
      PuppetCheck.future_parser = false
      PuppetCheck.style_check = false
      PuppetCheck.smoke_check = false
      PuppetCheck.regression_check = false
      PuppetCheck::CLI.parse(%w(-s -f -r --smoke foo))
      expect(PuppetCheck.future_parser).to eql(true)
      expect(PuppetCheck.style_check).to eql(true)
      expect(PuppetCheck.smoke_check).to eql(true)
      expect(PuppetCheck.regression_check).to eql(true)
    end

    it 'correctly parses a formatting option' do
      PuppetCheck.output_format = ''
      PuppetCheck::CLI.parse(%w(-o text))
      expect(PuppetCheck.output_format).to eql('text')
    end

    it 'correctly parses octocatalog-diff options' do
      PuppetCheck.octoconfig = ''
      PuppetCheck.octonodes = []
      PuppetCheck::CLI.parse(%w(--octoconfig config.cfg.rb --octonodes server1,server2))
      expect(PuppetCheck.octoconfig).to eql('config.cfg.rb')
      expect(PuppetCheck.octonodes).to eql(%w(server1 server2))
    end

    it 'correctly parses PuppetLint arguments' do
      PuppetCheck.puppetlint_args = []
      PuppetCheck::CLI.parse(%w(--puppet-lint puppetlint-arg-one,puppetlint-arg-two foo))
      expect(PuppetCheck.puppetlint_args).to eql(['--puppetlint-arg-one', '--puppetlint-arg-two'])
    end

    it 'correctly loads a .puppet-lint.rc' do
      PuppetCheck.puppetlint_args = []
      PuppetCheck::CLI.parse(%W(-c #{fixtures_dir}/manifests/.puppet-lint.rc))
      expect(PuppetCheck.puppetlint_args).to eql(['--puppetlint-arg-one', '--puppetlint-arg-two'])
    end

    it 'correctly parses Rubocop arguments' do
      PuppetCheck.rubocop_args = []
      PuppetCheck::CLI.parse(%w(--rubocop rubocop-arg-one,rubocop-arg-two foo))
      expect(PuppetCheck.rubocop_args).to eql(['--except', 'rubocop-arg-one,rubocop-arg-two'])
    end

    it 'correctly parses multiple sets of arguments' do
      PuppetCheck.future_parser = false
      PuppetCheck.style_check = false
      PuppetCheck.puppetlint_args = []
      PuppetCheck.rubocop_args = []
      PuppetCheck::CLI.parse(%w(-s -f --puppet-lint puppetlint-arg-one,puppetlint-arg-two --rubocop rubocop-arg-one,rubocop-arg-two foo))
      expect(PuppetCheck.future_parser).to eql(true)
      expect(PuppetCheck.style_check).to eql(true)
      expect(PuppetCheck.puppetlint_args).to eql(['--puppetlint-arg-one', '--puppetlint-arg-two'])
      expect(PuppetCheck.rubocop_args).to eql(['--except', 'rubocop-arg-one,rubocop-arg-two'])
    end
  end
end
