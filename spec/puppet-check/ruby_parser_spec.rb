require_relative '../spec_helper'
require_relative '../../lib/puppet-check/ruby_parser'

describe RubyParser do
  before(:each) do
    PuppetCheck.error_files = []
    PuppetCheck.warning_files = []
    PuppetCheck.clean_files = []
    PuppetCheck.style_check = false
    PuppetCheck.rubocop_args = []
  end

  context '.ruby' do
    it 'puts a bad syntax ruby file in the error files array' do
      RubyParser.ruby([fixtures_dir + 'lib/syntax.rb'])
      expect(PuppetCheck.error_files[0]).to match(%r{^\-\- #{fixtures_dir}lib/syntax.rb:\n.*syntax error})
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql([])
    end
    if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.1.0')
      it 'puts a bad style ruby file in the warning files array' do
        PuppetCheck.style_check = true
        RubyParser.ruby([fixtures_dir + 'lib/style.rb'])
        expect(PuppetCheck.error_files).to eql([])
        expect(PuppetCheck.warning_files[0]).to match(%r{^\-\- #{fixtures_dir}lib/style.rb:\n.*Useless assignment.*\n.*Use the new.*\n.*Do not introduce.*\n.*Prefer single.*\n.*is a writable attribute.*\n.*Issue has no descriptive comment})
        expect(PuppetCheck.clean_files).to eql([])
      end
    else
      it 'puts a bad style ruby file in the warning files array' do
        PuppetCheck.style_check = true
        RubyParser.ruby([fixtures_dir + 'lib/style.rb'])
        expect(PuppetCheck.error_files).to eql([])
        expect(PuppetCheck.warning_files[0]).to match(%r{^\-\- #{fixtures_dir}lib/style.rb:\n.*Useless assignment.*\n.*Use the new.*\n.*Do not introduce.*\n.*Prefer single})
        expect(PuppetCheck.clean_files).to eql([])
      end
    end
    it 'puts a bad style ruby file in the clean files array when rubocop_args ignores its warnings' do
      PuppetCheck.style_check = true
      PuppetCheck.rubocop_args = ['--except', 'Lint/UselessAssignment,Style/HashSyntax,Style/GlobalVars,Style/StringLiterals']
      RubyParser.ruby([fixtures_dir + 'lib/rubocop_style.rb'])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql(["-- #{fixtures_dir}lib/rubocop_style.rb"])
    end
    it 'puts a good ruby file in the clean files array' do
      PuppetCheck.style_check = true
      RubyParser.ruby([fixtures_dir + 'lib/good.rb'])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql(["-- #{fixtures_dir}lib/good.rb"])
    end
  end

  context '.template' do
    it 'puts a bad syntax ruby template file in the error files array' do
      RubyParser.template([fixtures_dir + 'templates/syntax.erb'])
      expect(PuppetCheck.error_files[0]).to match(%r{^\-\- #{fixtures_dir}templates/syntax.erb:\n.*syntax error, unexpected tIDENTIFIER})
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a bad style ruby template file in the warning files array' do
      RubyParser.template([fixtures_dir + 'templates/style.erb'])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files[0]).to match(%r{^\-\- #{fixtures_dir}templates/style.erb:\n.*already initialized constant.*\n.*(previous definition of|already initialized constant)})
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a good ruby template file in the clean files array' do
      RubyParser.template([fixtures_dir + 'templates/good.erb'])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql(["-- #{fixtures_dir}templates/good.erb"])
    end
  end

  context '.librarian' do
    it 'puts a bad syntax librarian Puppet file in the error files array' do
      RubyParser.librarian([fixtures_dir + 'librarian_syntax/Puppetfile'])
      expect(PuppetCheck.error_files[0]).to match(%r{^\-\- #{fixtures_dir}librarian_syntax/Puppetfile:\n.*syntax error})
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a bad style librarian Puppet file in the warning files array' do
      PuppetCheck.style_check = true
      RubyParser.librarian([fixtures_dir + 'librarian_style/Puppetfile'])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files[0]).to match(%r{^\-\- #{fixtures_dir}librarian_style/Puppetfile:\n.*Align the parameters.*\n.*Use the new})
      expect(PuppetCheck.clean_files).to eql([])
    end
    it 'puts a bad style librarian Puppet file in the clean files array when rubocop_args ignores its warnings' do
      PuppetCheck.style_check = true
      PuppetCheck.rubocop_args = ['--except', 'Style/AlignParameters,Style/HashSyntax']
      RubyParser.librarian([fixtures_dir + 'librarian_style/Puppetfile'])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql(["-- #{fixtures_dir}librarian_style/Puppetfile"])
    end
    it 'puts a good librarian Puppet file in the clean files array' do
      PuppetCheck.style_check = true
      RubyParser.librarian([fixtures_dir + 'librarian_good/Puppetfile'])
      expect(PuppetCheck.error_files).to eql([])
      expect(PuppetCheck.warning_files).to eql([])
      expect(PuppetCheck.clean_files).to eql(["-- #{fixtures_dir}librarian_good/Puppetfile"])
    end
  end
end
