require_relative '../spec_helper'
require_relative '../../lib/puppet-check/puppet_parser'

describe PuppetParser do
  before(:each) do
    PuppetCheck.files[:errors] = {}
    PuppetCheck.files[:warnings] = {}
    PuppetCheck.files[:clean] = []
  end

  context '.manifest' do
    it 'puts a bad syntax Puppet manifest in the error files hash' do
      PuppetParser.manifest(["#{fixtures_dir}manifests/syntax.pp"], false, [])
      expect(PuppetCheck.files[:errors].keys).to eql(["#{fixtures_dir}manifests/syntax.pp"])
      if Gem::Version.new(Puppet::PUPPETVERSION) >= Gem::Version.new('6.5.0')
        expect(PuppetCheck.files[:errors]["#{fixtures_dir}manifests/syntax.pp"].join("\n")).to match(%r{^Language validation logged 2 errors})
      else
        expect(PuppetCheck.files[:errors]["#{fixtures_dir}hieradata/syntax.yaml"].join("\n")).to match(%r{^This Variable has no effect.*\nIllegal variable name})
      end
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    # puppet 5 api has output issues for this fixture
    unless Gem::Version.new(Puppet::PUPPETVERSION) < Gem::Version.new('6.0.0')
      it 'puts a bad syntax at eof Puppet manifest in the error files hash' do
        PuppetParser.manifest(["#{fixtures_dir}manifests/eof_syntax.pp"], false, [])
        expect(PuppetCheck.files[:errors].keys).to eql(["#{fixtures_dir}manifests/eof_syntax.pp"])
        expect(PuppetCheck.files[:errors]["#{fixtures_dir}manifests/eof_syntax.pp"].join("\n")).to match(%r{^Syntax error at end of input})
        expect(PuppetCheck.files[:warnings]).to eql({})
        expect(PuppetCheck.files[:clean]).to eql([])
      end
    end
    it 'puts a bad syntax Puppet plan in the error files hash' do
      PuppetParser.manifest(["#{fixtures_dir}plans/syntax.pp"], false, [])
      expect(PuppetCheck.files[:errors].keys).to eql(["#{fixtures_dir}plans/syntax.pp"])
      expect(PuppetCheck.files[:errors]["#{fixtures_dir}plans/syntax.pp"].join("\n")).to match(%r{^Syntax error at '\)'})
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts a bad parser style and lint style Puppet manifest in the warning files array' do
      PuppetParser.manifest(["#{fixtures_dir}manifests/style_parser.pp"], true, [])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings].keys).to eql(["#{fixtures_dir}manifests/style_parser.pp"])
      expect(PuppetCheck.files[:warnings]["#{fixtures_dir}manifests/style_parser.pp"].join("\n")).to match(%r{^Unrecognized escape sequence.*\nUnrecognized escape sequence.*\n.*double quoted string containing})
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts a bad lint style Puppet manifest in the warning files array' do
      PuppetParser.manifest(["#{fixtures_dir}manifests/style_lint.pp"], true, [])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings].keys).to eql(["#{fixtures_dir}manifests/style_lint.pp"])
      expect(PuppetCheck.files[:warnings]["#{fixtures_dir}manifests/style_lint.pp"].join("\n")).to match(%r{(?:indentation of|double quoted string containing).*\n.*(?:indentation of|double quoted string containing)})
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts a bad style Puppet manifest in the clean files array when puppetlint_args ignores its warnings' do
      PuppetParser.manifest(["#{fixtures_dir}manifests/style_lint.pp"], true, ['--no-double_quoted_strings-check', '--no-arrow_alignment-check'])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql(["#{fixtures_dir}manifests/style_lint.pp"])
    end
    it 'puts a bad style Puppet plan in the warning files array' do
      PuppetParser.manifest(["#{fixtures_dir}plans/style.pp"], true, [])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings].keys).to eql(["#{fixtures_dir}plans/style.pp"])
      expect(PuppetCheck.files[:warnings]["#{fixtures_dir}plans/style.pp"].join("\n")).to match(%r{variable not enclosed in {}})
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts a good Puppet manifest in the clean files array' do
      PuppetParser.manifest(["#{fixtures_dir}manifests/good.pp"], true, [])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql(["#{fixtures_dir}manifests/good.pp"])
    end
    it 'puts a good Puppet plan in the clean files array' do
      PuppetParser.manifest(["#{fixtures_dir}plans/good.pp"], true, [])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql(["#{fixtures_dir}plans/good.pp"])
    end
    it 'throws a well specified error for an invalid PuppetLint argument' do
      expect { PuppetParser.manifest(["#{fixtures_dir}manifests/style_lint.pp"], true, ['--non-existent', '--does-not-exist']) }.to raise_error(RuntimeError, 'puppet-lint: invalid option supplied among --non-existent --does-not-exist')
    end
  end

  context '.template' do
    it 'puts a bad syntax Puppet template in the error files hash' do
      PuppetParser.template(["#{fixtures_dir}templates/syntax.epp"])
      expect(PuppetCheck.files[:errors].keys).to eql(["#{fixtures_dir}templates/syntax.epp"])
      expect(PuppetCheck.files[:errors]["#{fixtures_dir}templates/syntax.epp"].join("\n")).to match(%r{^This Name has no effect})
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts a good Puppet template in the clean files array' do
      PuppetParser.template(["#{fixtures_dir}templates/good.epp"])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql(["#{fixtures_dir}templates/good.epp"])
    end
  end
end
