require_relative '../spec_helper'
require_relative '../../lib/puppet-check/ruby_parser'

describe RubyParser do
  before(:each) do
    PuppetCheck.files = {
      errors: {},
      warnings: {},
      clean: [],
      ignored: []
    }
  end

  context '.ruby' do
    it 'puts a bad syntax ruby file in the error files hash' do
      RubyParser.ruby(["#{FIXTURES_DIR}lib/syntax.rb"], false, [])
      expect(PuppetCheck.files[:errors].keys).to eql(["#{FIXTURES_DIR}lib/syntax.rb"])
      expect(PuppetCheck.files[:errors]["#{FIXTURES_DIR}lib/syntax.rb"].join("\n")).to match(/^.*syntax error/)
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts a bad style ruby file in the warning files array' do
      RubyParser.ruby(["#{FIXTURES_DIR}lib/style.rb"], true, [])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings].keys).to eql(["#{FIXTURES_DIR}lib/style.rb"])
      unless CI_ENV
        expect(PuppetCheck.files[:warnings]["#{FIXTURES_DIR}lib/style.rb"].length).to eql(8)
      else
        expect(PuppetCheck.files[:warnings]["#{FIXTURES_DIR}lib/style.rb"].join("\n")).to match(/Useless assignment.*\n.*Use the new.*\n.*Do not introduce.*\n.*Prefer single.*\n.*Remove unnecessary empty.*\n.*Source code comment is empty/)
      end
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts a bad style ruby file in the clean files array when rubocop_args ignores its warnings' do
      RubyParser.ruby(["#{FIXTURES_DIR}lib/rubocop_style.rb"], true, ['--except', 'Lint/UselessAssignment,Style/HashSyntax,Style/GlobalVars,Style/StringLiterals'])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql(["#{FIXTURES_DIR}lib/rubocop_style.rb"])
    end
    it 'puts a good ruby file in the clean files array' do
      RubyParser.ruby(["#{FIXTURES_DIR}lib/good.rb"], true, [])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql(["#{FIXTURES_DIR}lib/good.rb"])
    end
  end

  context '.template' do
    it 'puts a bad syntax ruby template file in the error files hash' do
      RubyParser.template(["#{FIXTURES_DIR}templates/syntax.erb"])
      expect(PuppetCheck.files[:errors].keys).to eql(["#{FIXTURES_DIR}templates/syntax.erb"])
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7')
        expect(PuppetCheck.files[:errors]["#{FIXTURES_DIR}templates/syntax.erb"].join("\n")).to match(/1: syntax error, unexpected.*\n.*ruby/)
      else
        expect(PuppetCheck.files[:errors]["#{FIXTURES_DIR}templates/syntax.erb"].join("\n")).to match(/syntax error, unexpected tIDENTIFIER/)
      end
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts a bad style ruby template file in the warning files array' do
      RubyParser.template(["#{FIXTURES_DIR}templates/style.erb"])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings].keys).to eql(["#{FIXTURES_DIR}templates/style.erb"])
      expect(PuppetCheck.files[:warnings]["#{FIXTURES_DIR}templates/style.erb"].join("\n")).to match(/already initialized constant.*\n.*previous definition of/)
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts a ruby template file with ignored errors in the clean files array' do
      RubyParser.template(["#{FIXTURES_DIR}templates/no_method_error.erb"])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql(["#{FIXTURES_DIR}templates/no_method_error.erb"])
    end
    it 'puts a good ruby template file in the clean files array' do
      RubyParser.template(["#{FIXTURES_DIR}templates/good.erb"])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql(["#{FIXTURES_DIR}templates/good.erb"])
    end
  end

  context '.librarian' do
    it 'puts a bad syntax librarian Puppet file in the error files hash' do
      RubyParser.librarian(["#{FIXTURES_DIR}librarian/Puppetfile_syntax"], false, [])
      expect(PuppetCheck.files[:errors].keys).to eql(["#{FIXTURES_DIR}librarian/Puppetfile_syntax"])
      expect(PuppetCheck.files[:errors]["#{FIXTURES_DIR}librarian/Puppetfile_syntax"].join("\n")).to match(/^.*syntax error/)
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts a bad style librarian Puppet file in the warning files array' do
      RubyParser.librarian(["#{FIXTURES_DIR}librarian/Puppetfile_style"], true, [])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings].keys).to eql(["#{FIXTURES_DIR}librarian/Puppetfile_style"])
      expect(PuppetCheck.files[:warnings]["#{FIXTURES_DIR}librarian/Puppetfile_style"].join("\n")).to match(/Align the arguments.*\n.*Use the new/)
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts a bad style librarian Puppet file in the clean files array when rubocop_args ignores its warnings' do
      RubyParser.librarian(["#{FIXTURES_DIR}librarian/Puppetfile_style"], true, ['--except', 'Layout/ArgumentAlignment,Style/HashSyntax'])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql(["#{FIXTURES_DIR}librarian/Puppetfile_style"])
    end
    it 'puts a good librarian Puppet file in the clean files array' do
      RubyParser.librarian(["#{FIXTURES_DIR}librarian/Puppetfile_good"], true, [])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql(["#{FIXTURES_DIR}librarian/Puppetfile_good"])
    end
  end
end
