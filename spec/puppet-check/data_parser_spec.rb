require_relative '../spec_helper'
require_relative '../../lib/puppet-check/data_parser'

describe DataParser do
  before(:each) do
    PuppetCheck.error_files = []
    PuppetCheck.warning_files = []
    PuppetCheck.clean_files = []
  end

  context '.yaml' do
    it 'puts a bad syntax yaml file in the error files array' do
      DataParser.yaml([fixtures_dir + 'hieradata/syntax.yaml'])
      expect(PuppetCheck.error_files[0]).to match(%r{^#{fixtures_dir}hieradata/syntax.yaml:\nblock sequence entries are not allowed})
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a good yaml file with potential hiera issues in the warning files array' do
      DataParser.yaml([fixtures_dir + 'hieradata/style.yaml'])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files[0]).to match(%r{^#{fixtures_dir}hieradata/style.yaml:\nValue\(s\) missing in key.*\nValue\(s\) missing in key.*\nThe string --- appears more than once in this data and Hiera will fail to parse it correctly})
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a good yaml file in the clean files array' do
      DataParser.yaml([fixtures_dir + 'hieradata/good.yaml'])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql(["#{fixtures_dir}hieradata/good.yaml"])
    end
  end

  context '.json' do
    it 'puts a bad syntax json file in the error files array' do
      DataParser.json([fixtures_dir + 'hieradata/syntax.json'])
      expect(PuppetCheck.error_files[0]).to match(%r{^#{fixtures_dir}hieradata/syntax.json:\n.*unexpected token})
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a bad metadata json file in the error files array' do
      DataParser.json([fixtures_dir + 'metadata_syntax/metadata.json'])
      expect(PuppetCheck.error_files[0]).to match(%r{^#{fixtures_dir}metadata_syntax/metadata.json:\nRequired field.*\nField 'requirements'.*\nDuplicate dependencies.*\nDeprecated field.*\nSummary exceeds})
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a bad style metadata json file in the warning files array' do
      DataParser.json([fixtures_dir + 'metadata_style/metadata.json'])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files[0]).to match(%r{^#{fixtures_dir}metadata_style/metadata.json:\n.*operatingsystem_support.*\n'pe' is missing an upper bound.\nLicense identifier})
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts another bad style metadata json file in the warning files array' do
      DataParser.json([fixtures_dir + 'metadata_style_two/metadata.json'])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files[0]).to match(%r{^#{fixtures_dir}metadata_style_two/metadata.json:\n.*operatingsystem.*\n.*operatingsystemrelease.*\n'puppetlabs/one' has non-semantic versioning.*\n'puppetlabs/two' is missing an upper bound})
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a good json file in the clean files array' do
      DataParser.json([fixtures_dir + 'hieradata/good.json'])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql(["#{fixtures_dir}hieradata/good.json"])
    end
    it 'puts a good metadata json file in the clean files array' do
      DataParser.json([fixtures_dir + 'metadata_good/metadata.json'])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql(["#{fixtures_dir}metadata_good/metadata.json"])
    end
  end
end
