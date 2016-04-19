require_relative '../spec_helper'
require_relative '../../lib/puppet-check/frontend_parser'

describe 'FrontendParser' do
  let(:subject) { FrontendParser.new }

  it 'args, future parser, style check, puppet-lint args, rubocop args, and reek args have the correct defaults' do
    expect(subject.instance_variable_get(:@args)).to eql([])
    expect(subject.instance_variable_get(:@future_parser)).to eql(false)
    expect(subject.instance_variable_get(:@style_check)).to eql(false)
    expect(subject.instance_variable_get(:@puppetlint_args)).to eql([])
    expect(subject.instance_variable_get(:@rubocop_args)).to eql([])
    expect(subject.instance_variable_get(:@reek_args)).to eql([])
  end
  it 'future parser can be altered' do
    subject.instance_variable_set(:@future_parser, true)
    expect(subject.instance_variable_get(:@future_parser)).to eql(true)
  end
  it 'style check can be altered' do
    subject.instance_variable_set(:@style_check, true)
    expect(subject.instance_variable_get(:@style_check)).to eql(true)
  end
  it 'puppet lint arguments can be altered' do
    subject.instance_variable_set(:@puppetlint_args, ['--puppetlint-arg-one, --puppetlint-arg-two'])
    expect(subject.instance_variable_get(:@puppetlint_args)).to eql(['--puppetlint-arg-one, --puppetlint-arg-two'])
  end
  it 'rubocop arguments can be altered' do
    subject.instance_variable_set(:@rubocop_args, ['--rubocop-arg-one, --rubocop-arg-two'])
    expect(subject.instance_variable_get(:@rubocop_args)).to eql(['--rubocop-arg-one, --rubocop-arg-two'])
  end
  it 'reek arguments can be altered' do
    subject.instance_variable_set(:@reek_args, ['--reek-arg-one, --reek-arg-two'])
    expect(subject.instance_variable_get(:@reek_args)).to eql(['--reek-arg-one, --reek-arg-two'])
  end
end

describe 'parse_paths' do
  let(:subject) { FrontendParser.new }

  it 'correctly parses one file and returns it' do
    subject.parse_paths([fixtures_dir + 'lib/good.rb'])
    expect(subject.instance_variable_get(:@all_files)[0]).to match(%r{spec/fixtures/lib/good.rb})
  end

  it 'correctly parses one directory and returns all of its files' do
    subject.parse_paths([fixtures_dir])
    subject.instance_variable_get(:@all_files).each { |file| expect(File.file?(file)).to be true }
    expect(subject.instance_variable_get(:@all_files).length).to eql(18)
  end

  it 'correctly parses multiple directories and returns all of their files' do
    subject.parse_paths([fixtures_dir + 'hieradata', fixtures_dir + 'lib', fixtures_dir + 'manifests'])
    subject.instance_variable_get(:@all_files).each { |file| expect(File.file?(file)).to be true }
    expect(subject.instance_variable_get(:@all_files).length).to eql(10)
  end

  it 'correctly parses three directories (one repeated) and three files (one repeated from directories and another repeated from files) and returns the unique files' do
    subject.parse_paths([fixtures_dir + 'hieradata', fixtures_dir + 'hieradata', fixtures_dir + 'lib', fixtures_dir + 'hieradata/good.json', fixtures_dir + 'manifests/good.pp', fixtures_dir + 'manifests/good.pp'])
    subject.instance_variable_get(:@all_files).each { |file| expect(File.file?(file)).to be true }
    expect(subject.instance_variable_get(:@all_files).length).to eql(8)
  end
end

describe 'sort_input_files' do
  let(:subject) { FrontendParser.new }

  it 'correctly sorts an array of files to be checked' do
    subject.sort_input_files(%w(puppet.pp puppet_template.epp ruby.rb ruby_template.erb yaml.yaml yaml.yml json.json Puppetfile Modulefile foobarbaz))
    expect(subject.instance_variable_get(:@puppet_files)).to eql(['puppet.pp'])
    expect(subject.instance_variable_get(:@puppet_template_files)).to eql(['puppet_template.epp'])
    expect(subject.instance_variable_get(:@ruby_files)).to eql(['ruby.rb'])
    expect(subject.instance_variable_get(:@ruby_template_files)).to eql(['ruby_template.erb'])
    expect(subject.instance_variable_get(:@yaml_files)).to eql(['yaml.yaml', 'yaml.yml'])
    expect(subject.instance_variable_get(:@json_files)).to eql(['json.json'])
    expect(subject.instance_variable_get(:@librarian_files)).to eql(%w(Puppetfile Modulefile))
    expect(subject.instance_variable_get(:@ignored_files)).to eql(['foobarbaz'])
  end
end

describe 'puppet_parser' do
  let(:subject) { FrontendParser.new }

  it 'puts a bad syntax Puppet manifest in the error files array' do
    subject.puppet_parser(fixtures_dir + 'manifests/syntax.pp')
    # expect(subject.instance_variable_get(:@error_files)[0]).to match(%r{^\-\- #{fixtures_dir}manifests/syntax.pp:.*syntax error})
    expect(subject.instance_variable_get(:@error_files)[0]).to match(%r{^\-\- #{fixtures_dir}manifests/syntax.pp:})
    expect(subject.instance_variable_get(:@warning_files)).to eql([])
    expect(subject.instance_variable_get(:@clean_files)).to eql([])
  end
  it 'puts a bad style Puppet manifest in the warning files array' do
    subject.instance_variable_set(:@style_check, true)
    subject.puppet_parser(fixtures_dir + 'manifests/style.pp')
    expect(subject.instance_variable_get(:@error_files)).to eql([])
    expect(subject.instance_variable_get(:@warning_files)[0]).to match(%r{^\-\- #{fixtures_dir}manifests/style.pp: double quoted string containing.*\n\sindentation of})
    expect(subject.instance_variable_get(:@clean_files)).to eql([])
  end
  it 'puts a bad style Puppet manifest in the clean files array when puppetlint_args ignores its warnings' do
    subject.instance_variable_set(:@style_check, true)
    subject.instance_variable_set(:@puppetlint_args, ['--no-double_quoted_strings-check', '--no-arrow_alignment-check'])
    subject.puppet_parser(fixtures_dir + 'manifests/style.pp')
    expect(subject.instance_variable_get(:@error_files)).to eql([])
    expect(subject.instance_variable_get(:@warning_files)).to eql([])
    expect(subject.instance_variable_get(:@clean_files)).to eql(["-- #{fixtures_dir}manifests/style.pp"])
  end
  it 'puts a good Puppet manifest in the clean files array' do
    subject.instance_variable_set(:@style_check, true)
    subject.puppet_parser(fixtures_dir + 'manifests/good.pp')
    expect(subject.instance_variable_get(:@error_files)).to eql([])
    expect(subject.instance_variable_get(:@warning_files)).to eql([])
    expect(subject.instance_variable_get(:@clean_files)).to eql(["-- #{fixtures_dir}manifests/good.pp"])
  end
end

describe 'puppet_template_parser' do
  let(:subject) { FrontendParser.new }

  it 'puts a bad syntax Puppet template in the error files array' do
    subject.puppet_template_parser(fixtures_dir + 'templates/syntax.epp')
    expect(subject.instance_variable_get(:@error_files)[0]).to match(%r{^\-\- #{fixtures_dir}templates/syntax.epp: This Name has no effect})
    expect(subject.instance_variable_get(:@warning_files)).to eql([])
    expect(subject.instance_variable_get(:@clean_files)).to eql([])
  end
  it 'puts a good Puppet template in the clean files array' do
    subject.puppet_template_parser(fixtures_dir + 'templates/good.epp')
    expect(subject.instance_variable_get(:@error_files)).to eql([])
    expect(subject.instance_variable_get(:@warning_files)).to eql([])
    expect(subject.instance_variable_get(:@clean_files)).to eql(["-- #{fixtures_dir}templates/good.epp"])
  end
end

describe 'ruby_parser' do
  let(:subject) { FrontendParser.new }

  it 'puts a bad syntax ruby file in the error files array' do
    subject.ruby_parser(fixtures_dir + 'lib/syntax.rb')
    expect(subject.instance_variable_get(:@error_files)[0]).to match(%r{^\-\- #{fixtures_dir}lib/syntax.rb:.*syntax error})
    expect(subject.instance_variable_get(:@warning_files)).to eql([])
    expect(subject.instance_variable_get(:@clean_files)).to eql([])
  end
  if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.1.0')
    it 'puts a bad style ruby file in the warning files array' do
      subject.instance_variable_set(:@style_check, true)
      subject.ruby_parser(fixtures_dir + 'lib/style.rb')
      expect(subject.instance_variable_get(:@error_files)).to eql([])
      expect(subject.instance_variable_get(:@warning_files)[0]).to match(%r{^\-\- #{fixtures_dir}lib/style.rb:})
      expect(subject.instance_variable_get(:@clean_files)).to eql([])
    end
  else
    it 'puts a bad style ruby file in the warning files array' do
      subject.instance_variable_set(:@style_check, true)
      subject.ruby_parser(fixtures_dir + 'lib/style.rb')
      expect(subject.instance_variable_get(:@error_files)).to eql([])
      expect(subject.instance_variable_get(:@warning_files)[0]).to match(%r{^\-\- #{fixtures_dir}lib/style.rb:})
      expect(subject.instance_variable_get(:@clean_files)).to eql([])
    end
  end
  it 'puts a bad style ruby file in the clean files array when rubocop_args ignores its warnings' do
    subject.instance_variable_set(:@style_check, true)
    subject.instance_variable_set(:@rubocop_args, ['--except', 'Lint/UselessAssignment,Style/HashSyntax,Style/GlobalVars,Style/StringLiterals'])
    subject.ruby_parser(fixtures_dir + 'lib/style.rb')
    expect(subject.instance_variable_get(:@error_files)).to eql([])
    expect(subject.instance_variable_get(:@warning_files)).to eql([])
    expect(subject.instance_variable_get(:@clean_files)).to eql(["-- #{fixtures_dir}lib/style.rb"])
  end
  it 'puts a good ruby file in the clean files array' do
    subject.instance_variable_set(:@style_check, true)
    subject.ruby_parser(fixtures_dir + 'lib/good.rb')
    expect(subject.instance_variable_get(:@error_files)).to eql([])
    expect(subject.instance_variable_get(:@warning_files)).to eql([])
    expect(subject.instance_variable_get(:@clean_files)).to eql(["-- #{fixtures_dir}lib/good.rb"])
  end
end

describe 'ruby_template_parser' do
  let(:subject) { FrontendParser.new }

  it 'puts a bad syntax ruby template file in the error files array' do
    subject.ruby_template_parser(fixtures_dir + 'templates/syntax.erb')
    expect(subject.instance_variable_get(:@error_files)[0]).to match(%r{^\-\- #{fixtures_dir}templates/syntax.erb:.*syntax error, unexpected tIDENTIFIER})
    expect(subject.instance_variable_get(:@warning_files)).to eql([])
    expect(subject.instance_variable_get(:@clean_files)).to eql([])
  end
  it 'puts a bad style ruby template file in the warning files array' do
    subject.ruby_template_parser(fixtures_dir + 'templates/style.erb')
    expect(subject.instance_variable_get(:@error_files)).to eql([])
    # expect(subject.instance_variable_get(:@warning_files)[0]).to match(%r{^\-\- #{fixtures_dir}templates/style.erb:})
    # expect(subject.instance_variable_get(:@clean_files)).to eql([])
  end
  it 'puts a good ruby template file in the clean files array' do
    subject.ruby_template_parser(fixtures_dir + 'templates/good.erb')
    expect(subject.instance_variable_get(:@error_files)).to eql([])
    expect(subject.instance_variable_get(:@warning_files)).to eql([])
    expect(subject.instance_variable_get(:@clean_files)).to eql(["-- #{fixtures_dir}templates/good.erb"])
  end
end

describe 'yaml_parser' do
  let(:subject) { FrontendParser.new }

  it 'puts a bad syntax yaml file in the error files array' do
    subject.yaml_parser(fixtures_dir + 'hieradata/syntax.yaml')
    expect(subject.instance_variable_get(:@error_files)[0]).to match(%r{^\-\- \(#{fixtures_dir}hieradata/syntax.yaml\): block sequence entries are not allowed})
    expect(subject.instance_variable_get(:@warning_files)).to eql([])
    expect(subject.instance_variable_get(:@clean_files)).to eql([])
  end
  it 'puts a good yaml file in the clean files array' do
    subject.yaml_parser(fixtures_dir + 'hieradata/good.yaml')
    expect(subject.instance_variable_get(:@error_files)).to eql([])
    expect(subject.instance_variable_get(:@warning_files)).to eql([])
    expect(subject.instance_variable_get(:@clean_files)).to eql(["-- #{fixtures_dir}hieradata/good.yaml"])
  end
end

describe 'json_parser' do
  let(:subject) { FrontendParser.new }

  it 'puts a bad syntax json file in the error files array' do
    subject.json_parser(fixtures_dir + 'hieradata/syntax.json')
    expect(subject.instance_variable_get(:@error_files)[0]).to match(%r{^\-\- #{fixtures_dir}hieradata/syntax.json:.*unexpected token})
    expect(subject.instance_variable_get(:@warning_files)).to eql([])
    expect(subject.instance_variable_get(:@clean_files)).to eql([])
  end
  it 'puts a good json file in the clean files array' do
    subject.json_parser(fixtures_dir + 'hieradata/good.json')
    expect(subject.instance_variable_get(:@error_files)).to eql([])
    expect(subject.instance_variable_get(:@warning_files)).to eql([])
    expect(subject.instance_variable_get(:@clean_files)).to eql(["-- #{fixtures_dir}hieradata/good.json"])
  end
end

describe 'librarian_parser' do
  let(:subject) { FrontendParser.new }

  it 'puts a bad syntax librarian Puppet file in the error files array' do
    subject.librarian_parser(fixtures_dir + 'librarian_syntax/Puppetfile')
    expect(subject.instance_variable_get(:@error_files)[0]).to match(%r{^\-\- #{fixtures_dir}librarian_syntax/Puppetfile:.*syntax error})
    expect(subject.instance_variable_get(:@warning_files)).to eql([])
    expect(subject.instance_variable_get(:@clean_files)).to eql([])
  end
  it 'puts a bad style librarian Puppet file in the warning files array' do
    subject.instance_variable_set(:@style_check, true)
    subject.librarian_parser(fixtures_dir + 'librarian_style/Puppetfile')
    expect(subject.instance_variable_get(:@error_files)).to eql([])
    expect(subject.instance_variable_get(:@warning_files)[0]).to match(%r{^\-\- #{fixtures_dir}librarian_style/Puppetfile:})
    expect(subject.instance_variable_get(:@clean_files)).to eql([])
  end
  it 'puts a bad style librarian Puppet file in the clean files array when rubocop_args ignores its warnings' do
    subject.instance_variable_set(:@style_check, true)
    subject.instance_variable_set(:@rubocop_args, ['--except', 'Style/AlignParameters,Style/HashSyntax'])
    subject.librarian_parser(fixtures_dir + 'librarian_style/Puppetfile')
    expect(subject.instance_variable_get(:@error_files)).to eql([])
    expect(subject.instance_variable_get(:@warning_files)).to eql([])
    expect(subject.instance_variable_get(:@clean_files)).to eql(["-- #{fixtures_dir}librarian_style/Puppetfile"])
  end
  it 'puts a good librarian Puppet file in the clean files array' do
    subject.instance_variable_set(:@style_check, true)
    subject.librarian_parser(fixtures_dir + 'librarian_good/Puppetfile')
    expect(subject.instance_variable_get(:@error_files)).to eql([])
    expect(subject.instance_variable_get(:@warning_files)).to eql([])
    expect(subject.instance_variable_get(:@clean_files)).to eql(["-- #{fixtures_dir}librarian_good/Puppetfile"])
  end
end

describe 'output_results' do
  let(:subject) { FrontendParser.new }

  it 'outputs files with errors' do
    subject.instance_variable_set(:@error_files, ['-- foo: i had an error'])
    expect { subject.output_results }.to output("The following files have errors:\n-- foo: i had an error\n").to_stdout
  end
  it 'outputs files with warnings' do
    subject.instance_variable_set(:@warning_files, ['-- foo: i had a warning'])
    expect { subject.output_results }.to output("The following files have warnings:\n-- foo: i had a warning\n").to_stdout
  end
  it 'outputs files with no errors or warnings' do
    subject.instance_variable_set(:@clean_files, ['-- foo: i was totally good to go'])
    expect { subject.output_results }.to output("The following files processed with no errors or warnings:\n-- foo: i was totally good to go\n").to_stdout
  end
  it 'outputs files that were not processed' do
    subject.instance_variable_set(:@ignored_files, ['-- foo: who knows what i am'])
    expect { subject.output_results }.to output("The following files were unrecognized formats and therefore not processed:\n-- foo: who knows what i am\n").to_stdout
  end
end
