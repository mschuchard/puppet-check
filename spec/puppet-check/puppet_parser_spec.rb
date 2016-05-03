require_relative '../spec_helper'
require_relative '../../lib/puppet-check/puppet_parser'

describe PuppetParser do
  before(:each) do
    PuppetCheck.error_files = []
    PuppetCheck.warning_files = []
    PuppetCheck.clean_files = []
    PuppetCheck.future_parser = false
    PuppetCheck.style_check = false
    PuppetCheck.puppetlint_args = []
  end

  context '.manifest' do
    it 'puts a bad syntax Puppet manifest in the error files array' do
      PuppetParser.manifest([fixtures_dir + 'manifests/syntax.pp'])
      # expect(subject.instance_variable_get(:@error_files)[0]).to match(%r{^\-\- #{fixtures_dir}manifests/syntax.pp:.*syntax error})
      expect(PuppetCheck.error_files[0]).to match(%r{^\-\- #{fixtures_dir}manifests/syntax.pp:\nThis Variable has no effect.*\nIllegal variable name})
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a bad style Puppet manifest in the warning files array' do
      PuppetCheck.style_check = true
      PuppetParser.manifest([fixtures_dir + 'manifests/style.pp'])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files[0]).to match(%r{^\-\- #{fixtures_dir}manifests/style.pp:\ndouble quoted string containing.*\nindentation of})
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a bad style Puppet manifest in the clean files array when puppetlint_args ignores its warnings' do
      PuppetCheck.style_check = true
      PuppetCheck.puppetlint_args = ['--no-double_quoted_strings-check', '--no-arrow_alignment-check']
      PuppetParser.manifest([fixtures_dir + 'manifests/style.pp'])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql(["-- #{fixtures_dir}manifests/style.pp"])
    end
    it 'puts a good Puppet manifest in the clean files array' do
      PuppetCheck.style_check = true
      PuppetParser.manifest([fixtures_dir + 'manifests/good.pp'])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql(["-- #{fixtures_dir}manifests/good.pp"])
    end
  end

  context '.template' do
    it 'puts a bad syntax Puppet template in the error files array' do
      PuppetParser.template([fixtures_dir + 'templates/syntax.epp'])
      expect(PuppetCheck.error_files[0]).to match(%r{^\-\- #{fixtures_dir}templates/syntax.epp:\nThis Name has no effect})
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a good Puppet template in the clean files array' do
      PuppetParser.template([fixtures_dir + 'templates/good.epp'])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql(["-- #{fixtures_dir}templates/good.epp"])
    end
  end
end
