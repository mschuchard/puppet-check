require_relative '../spec_helper'
require_relative '../../lib/puppet-check/puppet_parser'

describe PuppetParser do
  before(:each) do
    PuppetCheck.settings[:error_files] = {}
    PuppetCheck.settings[:warning_files] = []
    PuppetCheck.settings[:clean_files] = {}
  end

  context '.manifest' do
    it 'puts a bad syntax Puppet manifest in the error files array' do
      PuppetParser.manifest(["#{fixtures_dir}manifests/syntax.pp"], false, [])
      expect(PuppetCheck.settings[:error_files].keys).to eql(["#{fixtures_dir}manifests/syntax.pp"])
      if Gem::Version.new(Puppet::PUPPETVERSION) >= Gem::Version.new('6.5.0')
        expect(PuppetCheck.settings[:error_files]["#{fixtures_dir}manifests/syntax.pp"]).to match(%r{^Language validation logged 2 errors})
      else
        expect(PuppetCheck.settings[:error_files]["#{fixtures_dir}hieradata/syntax.yaml"]).to match(%r{^This Variable has no effect.*\nIllegal variable name})
      end
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql({})
    end
    # puppet 5 api has output issues for this fixture
    unless Gem::Version.new(Puppet::PUPPETVERSION) < Gem::Version.new('6.0.0')
      it 'puts a bad syntax at eof Puppet manifest in the error files array' do
        PuppetParser.manifest(["#{fixtures_dir}manifests/eof_syntax.pp"], false, [])
        expect(PuppetCheck.settings[:error_files].keys).to eql(["#{fixtures_dir}manifests/eof_syntax.pp"])
        expect(PuppetCheck.settings[:error_files]["#{fixtures_dir}manifests/eof_syntax.pp"]).to match(%r{^Syntax error at end of input})
        expect(PuppetCheck.settings[:warning_files]).to eql([])
        expect(PuppetCheck.settings[:clean_files]).to eql({})
      end
    end
    it 'puts a bad syntax Puppet plan in the error files array' do
      PuppetParser.manifest(["#{fixtures_dir}plans/syntax.pp"], false, [])
      expect(PuppetCheck.settings[:error_files].keys).to eql(["#{fixtures_dir}plans/syntax.pp"])
      expect(PuppetCheck.settings[:error_files]["#{fixtures_dir}plans/syntax.pp"]).to match(%r{^Syntax error at '\)'})
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql({})
    end
    it 'puts a bad parser and lint style Puppet manifest in the warning files array' do
      PuppetParser.manifest(["#{fixtures_dir}manifests/style_parser.pp"], true, [])
      expect(PuppetCheck.settings[:error_files]).to eql({})
      expect(PuppetCheck.settings[:warning_files][0]).to match(%r{^#{fixtures_dir}manifests/style_parser.pp:\nUnrecognized escape sequence.*\nUnrecognized escape sequence.*\n.*double quoted string containing})
      expect(PuppetCheck.settings[:clean_files]).to eql({})
    end
    it 'puts a bad lint style Puppet manifest in the warning files array' do
      PuppetParser.manifest(["#{fixtures_dir}manifests/style_lint.pp"], true, [])
      expect(PuppetCheck.settings[:error_files]).to eql({})
      expect(PuppetCheck.settings[:warning_files][0]).to match(%r{^#{fixtures_dir}manifests/style_lint.pp:\n.*(?:indentation of|double quoted string containing).*\n.*(?:indentation of|double quoted string containing)})
      expect(PuppetCheck.settings[:clean_files]).to eql({})
    end
    it 'puts a bad style Puppet manifest in the clean files hash when puppetlint_args ignores its warnings' do
      PuppetParser.manifest(["#{fixtures_dir}manifests/style_lint.pp"], true, ['--no-double_quoted_strings-check', '--no-arrow_alignment-check'])
      expect(PuppetCheck.settings[:error_files]).to eql({})
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql({ "#{fixtures_dir}manifests/style_lint.pp" => nil })
    end
    it 'puts a bad style Puppet plan in the warning files array' do
      PuppetParser.manifest(["#{fixtures_dir}plans/style.pp"], true, [])
      expect(PuppetCheck.settings[:error_files]).to eql({})
      expect(PuppetCheck.settings[:warning_files][0]).to match(%r{^#{fixtures_dir}plans/style.pp:\n.*variable not enclosed in {}})
      expect(PuppetCheck.settings[:clean_files]).to eql({})
    end
    it 'puts a good Puppet manifest in the clean files hash' do
      PuppetParser.manifest(["#{fixtures_dir}manifests/good.pp"], true, [])
      expect(PuppetCheck.settings[:error_files]).to eql({})
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql({ "#{fixtures_dir}manifests/good.pp" => nil })
    end
    it 'puts a good Puppet plan in the clean files hash' do
      PuppetParser.manifest(["#{fixtures_dir}plans/good.pp"], true, [])
      expect(PuppetCheck.settings[:error_files]).to eql({})
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql({ "#{fixtures_dir}plans/good.pp" => nil })
    end
    it 'throws a well specified error for an invalid PuppetLint argument' do
      expect { PuppetParser.manifest(["#{fixtures_dir}manifests/style_lint.pp"], true, ['--non-existent', '--does-not-exist']) }.to raise_error(RuntimeError, 'puppet-lint: invalid option supplied among --non-existent --does-not-exist')
    end
  end

  context '.template' do
    it 'puts a bad syntax Puppet template in the error files array' do
      PuppetParser.template(["#{fixtures_dir}templates/syntax.epp"])
      expect(PuppetCheck.settings[:error_files].keys).to eql(["#{fixtures_dir}templates/syntax.epp"])
      expect(PuppetCheck.settings[:error_files]["#{fixtures_dir}templates/syntax.epp"]).to match(%r{^This Name has no effect})
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql({})
    end
    it 'puts a good Puppet template in the clean files hash' do
      PuppetParser.template(["#{fixtures_dir}templates/good.epp"])
      expect(PuppetCheck.settings[:error_files]).to eql({})
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql({ "#{fixtures_dir}templates/good.epp" => nil })
    end
  end
end
