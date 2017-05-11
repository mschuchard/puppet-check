require_relative '../spec_helper'
require_relative '../../lib/puppet-check/data_parser'

describe DataParser do
  before(:each) do
    PuppetCheck.settings['error_files'] = []
    PuppetCheck.settings['warning_files'] = []
    PuppetCheck.settings['clean_files'] = []
  end

  context '.yaml' do
    it 'puts a bad syntax yaml file in the error files array' do
      DataParser.yaml([fixtures_dir + 'hieradata/syntax.yaml'])
      expect(PuppetCheck.settings['error_files'][0]).to match(%r{^#{fixtures_dir}hieradata/syntax.yaml:\nblock sequence entries are not allowed})
      expect(PuppetCheck.settings['warning_files']).to eql([])
      expect(PuppetCheck.settings['clean_files']).to eql([])
    end
    it 'puts a good yaml file with potential hiera issues in the warning files array' do
      DataParser.yaml([fixtures_dir + 'hieradata/style.yaml'])
      expect(PuppetCheck.settings['error_files']).to eql([])
      expect(PuppetCheck.settings['warning_files'][0]).to match(%r{^#{fixtures_dir}hieradata/style.yaml:\nValue\(s\) missing in key.*\nValue\(s\) missing in key.*\nThe string --- appears more than once in this data and Hiera will fail to parse it correctly})
      expect(PuppetCheck.settings['clean_files']).to eql([])
    end
    it 'puts a good yaml file in the clean files array' do
      DataParser.yaml([fixtures_dir + 'hieradata/good.yaml'])
      expect(PuppetCheck.settings['error_files']).to eql([])
      expect(PuppetCheck.settings['warning_files']).to eql([])
      expect(PuppetCheck.settings['clean_files']).to eql(["#{fixtures_dir}hieradata/good.yaml"])
    end
  end

  context '.json' do
    it 'puts a bad syntax json file in the error files array' do
      DataParser.json([fixtures_dir + 'hieradata/syntax.json'])
      expect(PuppetCheck.settings['error_files'][0]).to match(%r{^#{fixtures_dir}hieradata/syntax.json:\n.*unexpected token})
      expect(PuppetCheck.settings['warning_files']).to eql([])
      expect(PuppetCheck.settings['clean_files']).to eql([])
    end
    it 'puts a bad metadata json file in the error files array' do
      DataParser.json([fixtures_dir + 'metadata_syntax/metadata.json'])
      expect(PuppetCheck.settings['error_files'][0]).to match(%r{^#{fixtures_dir}metadata_syntax/metadata.json:\nRequired field.*\nField 'requirements'.*\nDuplicate dependencies.*\nDeprecated field.*\nSummary exceeds})
      expect(PuppetCheck.settings['warning_files']).to eql([])
      expect(PuppetCheck.settings['clean_files']).to eql([])
    end
    it 'puts a bad style metadata json file in the warning files array' do
      DataParser.json([fixtures_dir + 'metadata_style/metadata.json'])
      expect(PuppetCheck.settings['error_files']).to eql([])
      expect(PuppetCheck.settings['warning_files'][0]).to match(%r{^#{fixtures_dir}metadata_style/metadata.json:\n'pe' is missing an upper bound.\n.*operatingsystem_support.*\nLicense identifier})
      expect(PuppetCheck.settings['clean_files']).to eql([])
    end
    it 'puts another bad style metadata json file in the warning files array' do
      DataParser.json([fixtures_dir + 'metadata_style_two/metadata.json'])
      expect(PuppetCheck.settings['error_files']).to eql([])
      expect(PuppetCheck.settings['warning_files'][0]).to match(%r{^#{fixtures_dir}metadata_style_two/metadata.json:\n'puppetlabs/one' has non-semantic versioning.*\n'puppetlabs/two' is missing an upper bound\.\n.*operatingsystem.*\n.*operatingsystemrelease})
      expect(PuppetCheck.settings['clean_files']).to eql([])
    end
    it 'puts a good json file in the clean files array' do
      DataParser.json([fixtures_dir + 'hieradata/good.json'])
      expect(PuppetCheck.settings['error_files']).to eql([])
      expect(PuppetCheck.settings['warning_files']).to eql([])
      expect(PuppetCheck.settings['clean_files']).to eql(["#{fixtures_dir}hieradata/good.json"])
    end
    it 'puts a good metadata json file in the clean files array' do
      DataParser.json([fixtures_dir + 'metadata_good/metadata.json'])
      expect(PuppetCheck.settings['error_files']).to eql([])
      expect(PuppetCheck.settings['warning_files']).to eql([])
      expect(PuppetCheck.settings['clean_files']).to eql(["#{fixtures_dir}metadata_good/metadata.json"])
    end
  end
end
