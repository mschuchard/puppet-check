require_relative '../spec_helper'
require_relative '../../lib/puppet-check/puppet_parser'

describe PuppetCheck::PuppetParser do
  before(:each) do
    PuppetCheck.error_files = []
    PuppetCheck.warning_files = []
    PuppetCheck.clean_files = []
  end

  context '.manifest' do
    it 'puts a bad syntax Puppet manifest in the error files array' do
      PuppetCheck::PuppetParser.manifest(fixtures_dir + 'manifests/syntax.pp', [])
      # expect(subject.instance_variable_get(:@error_files)[0]).to match(%r{^\-\- #{fixtures_dir}manifests/syntax.pp:.*syntax error})
      expect(PuppetCheck.error_files[0]).to match(%r{^\-\- #{fixtures_dir}manifests/syntax.pp:})
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a bad style Puppet manifest in the warning files array' do
      PuppetCheck.instance_variable_set(:@style_check, true)
      PuppetCheck::PuppetParser.manifest(fixtures_dir + 'manifests/style.pp', [])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files[0]).to match(%r{^\-\- #{fixtures_dir}manifests/style.pp: double quoted string containing.*\n\sindentation of})
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a bad style Puppet manifest in the clean files array when puppetlint_args ignores its warnings' do
      PuppetCheck.instance_variable_set(:@style_check, true)
      PuppetCheck::PuppetParser.manifest(fixtures_dir + 'manifests/style.pp', ['--no-double_quoted_strings-check', '--no-arrow_alignment-check'])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql(["-- #{fixtures_dir}manifests/style.pp"])
    end
    it 'puts a good Puppet manifest in the clean files array' do
      PuppetCheck.instance_variable_set(:@style_check, true)
      PuppetCheck::PuppetParser.manifest(fixtures_dir + 'manifests/good.pp', [])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql(["-- #{fixtures_dir}manifests/good.pp"])
    end
  end

  context '.template' do
    it 'puts a bad syntax Puppet template in the error files array' do
      PuppetCheck::PuppetParser.template(fixtures_dir + 'templates/syntax.epp')
      expect(PuppetCheck.error_files[0]).to match(%r{^\-\- #{fixtures_dir}templates/syntax.epp: This Name has no effect})
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a good Puppet template in the clean files array' do
      PuppetCheck::PuppetParser.template(fixtures_dir + 'templates/good.epp')
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql(["-- #{fixtures_dir}templates/good.epp"])
    end
  end
end
