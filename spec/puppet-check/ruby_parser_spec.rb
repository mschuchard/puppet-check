require_relative '../spec_helper'
require_relative '../../lib/puppet-check/ruby_parser'

describe RubyParser do
  before(:each) do
    PuppetCheck.settings[:error_files] = []
    PuppetCheck.settings[:warning_files] = []
    PuppetCheck.settings[:clean_files] = []
  end

  context '.ruby' do
    it 'puts a bad syntax ruby file in the error files array' do
      RubyParser.ruby(["#{fixtures_dir}lib/syntax.rb"], false, [])
      expect(PuppetCheck.settings[:error_files][0]).to match(%r{^#{fixtures_dir}lib/syntax.rb:\n.*syntax error})
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql([])
    end
    it 'puts a bad style ruby file in the warning files array' do
      RubyParser.ruby(["#{fixtures_dir}lib/style.rb"], true, [])
      expect(PuppetCheck.settings[:error_files]).to eql([])
      expect(PuppetCheck.settings[:warning_files][0]).to match(%r{^#{fixtures_dir}lib/style.rb:\n.*Useless assignment.*\n.*Use the new.*\n.*Do not introduce.*\n.*Prefer single.*\n.*Source code comment is empty.*\n.*is a writable attribute.*\n.*Issue has no descriptive comment})
      expect(PuppetCheck.settings[:clean_files]).to eql([])
    end
    it 'puts a bad style ruby file in the clean files array when rubocop_args ignores its warnings' do
      RubyParser.ruby(["#{fixtures_dir}lib/rubocop_style.rb"], true, ['--except', 'Lint/UselessAssignment,Style/HashSyntax,Style/GlobalVars,Style/StringLiterals'])
      expect(PuppetCheck.settings[:error_files]).to eql([])
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql(["#{fixtures_dir}lib/rubocop_style.rb"])
    end
    it 'puts a good ruby file in the clean files array' do
      RubyParser.ruby(["#{fixtures_dir}lib/good.rb"], true, [])
      expect(PuppetCheck.settings[:error_files]).to eql([])
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql(["#{fixtures_dir}lib/good.rb"])
    end
  end

  context '.template' do
    it 'puts a bad syntax ruby template file in the error files array' do
      RubyParser.template(["#{fixtures_dir}templates/syntax.erb"])
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7')
        expect(PuppetCheck.settings[:error_files][0]).to match(%r{^#{fixtures_dir}templates/syntax.erb:\n.*1: syntax error, unexpected.*\n.*ruby})
      else
        expect(PuppetCheck.settings[:error_files][0]).to match(%r{^#{fixtures_dir}templates/syntax.erb:\n.*syntax error, unexpected tIDENTIFIER})
      end
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql([])
    end
    it 'puts a bad style ruby template file in the warning files array' do
      RubyParser.template(["#{fixtures_dir}templates/style.erb"])
      expect(PuppetCheck.settings[:error_files]).to eql([])
      expect(PuppetCheck.settings[:warning_files][0]).to match(%r{^#{fixtures_dir}templates/style.erb:\n.*already initialized constant.*\n.*previous definition of})
      expect(PuppetCheck.settings[:clean_files]).to eql([])
    end
    it 'puts a ruby template file with ignored errors in the clean files array' do
      RubyParser.template(["#{fixtures_dir}templates/no_method_error.erb"])
      expect(PuppetCheck.settings[:error_files]).to eql([])
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql(["#{fixtures_dir}templates/no_method_error.erb"])
    end
    it 'puts a good ruby template file in the clean files array' do
      RubyParser.template(["#{fixtures_dir}templates/good.erb"])
      expect(PuppetCheck.settings[:error_files]).to eql([])
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql(["#{fixtures_dir}templates/good.erb"])
    end
  end

  context '.librarian' do
    it 'puts a bad syntax librarian Puppet file in the error files array' do
      RubyParser.librarian(["#{fixtures_dir}librarian_syntax/Puppetfile"], false, [])
      expect(PuppetCheck.settings[:error_files][0]).to match(%r{^#{fixtures_dir}librarian_syntax/Puppetfile:\n.*syntax error})
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql([])
    end
    it 'puts a bad style librarian Puppet file in the warning files array' do
      RubyParser.librarian(["#{fixtures_dir}librarian_style/Puppetfile"], true, [])
      expect(PuppetCheck.settings[:error_files]).to eql([])
      expect(PuppetCheck.settings[:warning_files][0]).to match(%r{^#{fixtures_dir}librarian_style/Puppetfile:\n.*Align the arguments.*\n.*Use the new})
      expect(PuppetCheck.settings[:clean_files]).to eql([])
    end
    it 'puts a bad style librarian Puppet file in the clean files array when rubocop_args ignores its warnings' do
      RubyParser.librarian(["#{fixtures_dir}librarian_style/Puppetfile"], true, ['--except', 'Layout/AlignArguments,Style/HashSyntax'])
      expect(PuppetCheck.settings[:error_files]).to eql([])
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql(["#{fixtures_dir}librarian_style/Puppetfile"])
    end
    it 'puts a good librarian Puppet file in the clean files array' do
      RubyParser.librarian(["#{fixtures_dir}librarian_good/Puppetfile"], true, [])
      expect(PuppetCheck.settings[:error_files]).to eql([])
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql(["#{fixtures_dir}librarian_good/Puppetfile"])
    end
  end
end
