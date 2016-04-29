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
      DataParser.yaml(fixtures_dir + 'hieradata/syntax.yaml')
      expect(PuppetCheck.error_files[0]).to match(%r{^\-\- \(#{fixtures_dir}hieradata/syntax.yaml\): block sequence entries are not allowed})
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a good yaml file in the clean files array' do
      DataParser.yaml(fixtures_dir + 'hieradata/good.yaml')
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql(["-- #{fixtures_dir}hieradata/good.yaml"])
    end
  end

  context '.json' do
    it 'puts a bad syntax json file in the error files array' do
      DataParser.json(fixtures_dir + 'hieradata/syntax.json')
      expect(PuppetCheck.error_files[0]).to match(%r{^\-\- #{fixtures_dir}hieradata/syntax.json:.*unexpected token})
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a bad metadata json file in the error files array' do
      DataParser.json(fixtures_dir + 'metadata_syntax/metadata.json')
      expect(PuppetCheck.error_files[0]).to match(%r{^\-\- #{fixtures_dir}metadata_syntax/metadata.json: Required field.*\nDuplicate dependencies.*\nDeprecated field.*\nSummary exceeds})
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a bad style metadata json file in the warning files array' do
      DataParser.json(fixtures_dir + 'metadata_style/metadata.json')
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files[0]).to match(%r{^\-\- #{fixtures_dir}metadata_style/metadata.json: License identifier})
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a good json file in the clean files array' do
      DataParser.json(fixtures_dir + 'hieradata/good.json')
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql(["-- #{fixtures_dir}hieradata/good.json"])
    end
    it 'puts a good metadata json file in the clean files array' do
      DataParser.json(fixtures_dir + 'metadata_good/metadata.json')
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql(["-- #{fixtures_dir}metadata_good/metadata.json"])
    end
  end
end
