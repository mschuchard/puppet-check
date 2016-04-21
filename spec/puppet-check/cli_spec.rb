require_relative '../spec_helper'
require_relative '../../lib/puppet-check/cli'

describe PuppetCheck::CLI do
  context '.run' do
    it 'raises an error if no paths were specified' do
      expect { PuppetCheck::CLI.run(%w(-s -f)) }.to raise_error(RuntimeError, 'puppet-check: no paths specified')
    end
  end

  context '.parse' do
    it 'raises an error if an invalid option was specified' do
      expect { PuppetCheck::CLI.parse(%w(-s -f -asdf foo)) }.to raise_error(OptionParser::InvalidOption)
    end

    it 'allows future parser and style check to be enabled' do
      PuppetCheck::CLI.parse(%w(-s -f foo))
      expect(PuppetCheck.future_parser).to eql(true)
      expect(PuppetCheck.style_check).to eql(true)
    end

    it 'correctly parses PuppetLint arguments' do
      #
    end

    it 'correctly parses Rubocop arguments' do
      #
    end

    it 'correctly parses Reek arguments' do
      #
    end
  end
end
