require_relative '../spec_helper'
require_relative '../../lib/puppet-check/data_parser'

describe PuppetCheck::DataParser do
  before(:each) do
    PuppetCheck.error_files = []
    PuppetCheck.warning_files = []
    PuppetCheck.clean_files = []
  end

  context '.yaml' do
    it 'puts a bad syntax yaml file in the error files array' do
      PuppetCheck::DataParser.yaml(fixtures_dir + 'hieradata/syntax.yaml')
      expect(PuppetCheck.error_files[0]).to match(%r{^\-\- \(#{fixtures_dir}hieradata/syntax.yaml\): block sequence entries are not allowed})
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a good yaml file in the clean files array' do
      PuppetCheck::DataParser.yaml(fixtures_dir + 'hieradata/good.yaml')
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql(["-- #{fixtures_dir}hieradata/good.yaml"])
    end
  end

  context '.json' do
    it 'puts a bad syntax json file in the error files array' do
      PuppetCheck::DataParser.json(fixtures_dir + 'hieradata/syntax.json')
      expect(PuppetCheck.error_files[0]).to match(%r{^\-\- #{fixtures_dir}hieradata/syntax.json:.*unexpected token})
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a good json file in the clean files array' do
      PuppetCheck::DataParser.json(fixtures_dir + 'hieradata/good.json')
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql(["-- #{fixtures_dir}hieradata/good.json"])
    end
  end
end
