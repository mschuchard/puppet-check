require_relative '../spec_helper'
require_relative '../../lib/puppet-check/cli'

describe PuppetCheck::CLI do
  context '.run' do
    it 'targets the current working directory if no paths were specified' do
      expect { PuppetCheck::CLI.run(%w[--fail-on-warnings]) }.not_to raise_exception
      expect(PuppetCheck.files[:clean].length).to eql(30)
      expect(PuppetCheck.files[:ignored].length).to eql(7)
    end
  end

  context '.parse' do
    it 'raises an error if an invalid option was specified' do
      expect { PuppetCheck::CLI.send(:parse, %w[-s -asdf foo]) }.to raise_error(OptionParser::InvalidOption)
    end

    it 'allows fail on warnings, style, smoke, and regression checks to be enabled' do
      expect(PuppetCheck::CLI.send(:parse, %w[--fail-on-warnings -s -r --smoke foo])).to include(fail_on_warnings: true, style: true, smoke: true, regression: true)
    end

    it 'correctly parser EYAML options' do
      expect(PuppetCheck::CLI.send(:parse, %w[--public pub.pem --private priv.pem])).to include(public: 'pub.pem', private: 'priv.pem')
    end

    it 'correctly parses a formatting option' do
      expect(PuppetCheck::CLI.send(:parse, %w[-o text])).to include(output_format: 'text')
    end

    it 'correctly parses octocatalog-diff options' do
      expect(PuppetCheck::CLI.send(:parse, %w[--octoconfig config.cfg.rb --octonodes server1,server2])).to include(octoconfig: 'config.cfg.rb', octonodes: %w[server1 server2])
    end

    it 'correctly parses PuppetLint arguments' do
      expect(PuppetCheck::CLI.send(:parse, %w[--puppet-lint puppetlint-arg-one,puppetlint-arg-two foo])).to include(puppetlint_args: ['--puppetlint-arg-one', '--puppetlint-arg-two'])
    end

    it 'correctly loads a .puppet-lint.rc' do
      expect(PuppetCheck::CLI.send(:parse, %W[-c #{fixtures_dir}/manifests/.puppet-lint.rc])).to include(puppetlint_args: ['--puppetlint-arg-one', '--puppetlint-arg-two'])
    end

    it 'correctly parses Rubocop arguments' do
      expect(PuppetCheck::CLI.send(:parse, %w[--rubocop rubocop-arg-one,rubocop-arg-two foo])).to include(rubocop_args: ['--except', 'rubocop-arg-one,rubocop-arg-two'])
    end

    it 'correctly parses multiple sets of arguments' do
      expect(PuppetCheck::CLI.send(:parse, %w[-s --puppet-lint puppet-lint-arg-one,puppet-lint-arg-two --rubocop rubocop-arg-one,rubocop-arg-two foo])).to include(style: true, puppetlint_args: ['--puppet-lint-arg-one', '--puppet-lint-arg-two'], rubocop_args: ['--except', 'rubocop-arg-one,rubocop-arg-two'])
    end
  end
end
