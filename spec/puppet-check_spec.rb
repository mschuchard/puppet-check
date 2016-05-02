require_relative 'spec_helper'
require_relative '../lib/puppet-check'

describe PuppetCheck do
  let(:puppetcheck) { PuppetCheck.new }

  context 'initializes and' do
    it 'future parser can be altered' do
      PuppetCheck.future_parser = true
      expect(PuppetCheck.future_parser).to eql(true)
    end
    it 'style check can be altered' do
      PuppetCheck.style_check = true
      expect(PuppetCheck.style_check).to eql(true)
    end
    it 'puppet lint arguments can be altered' do
      PuppetCheck.puppetlint_args = ['--puppetlint-arg-one', '--puppetlint-arg-two']
      expect(PuppetCheck.puppetlint_args).to eql(['--puppetlint-arg-one', '--puppetlint-arg-two'])
    end
    it 'rubocop arguments can be altered' do
      PuppetCheck.rubocop_args = ['--rubocop-arg-one', '--rubocop-arg-two']
      expect(PuppetCheck.rubocop_args).to eql(['--rubocop-arg-one', '--rubocop-arg-two'])
    end
  end

  context '.parse_paths' do
    let(:no_files) { puppetcheck.parse_paths(%w(foo bar baz)) }
    let(:file) { puppetcheck.parse_paths([fixtures_dir + 'lib/good.rb']) }
    let(:dir) { puppetcheck.parse_paths([fixtures_dir]) }
    let(:multi_dir) { puppetcheck.parse_paths([fixtures_dir + 'hieradata', fixtures_dir + 'lib', fixtures_dir + 'manifests']) }
    let(:repeats) { puppetcheck.parse_paths([fixtures_dir + 'hieradata', fixtures_dir + 'hieradata', fixtures_dir + 'lib', fixtures_dir + 'hieradata/good.json', fixtures_dir + 'manifests/good.pp', fixtures_dir + 'manifests/good.pp']) }

    it 'raises an error if no files were found' do
      expect { no_files }.to raise_error(RuntimeError, 'No files found in supplied paths foo, bar, baz.')
    end

    it 'correctly parses one file and returns it' do
      expect(file[0]).to match(%r{spec/fixtures/lib/good.rb})
    end

    it 'correctly parses one directory and returns all of its files' do
      dir.each { |file| expect(File.file?(file)).to be true }
      expect(dir.length).to eql(24)
    end

    it 'correctly parses multiple directories and returns all of their files' do
      multi_dir.each { |file| expect(File.file?(file)).to be true }
      expect(multi_dir.length).to eql(12)
    end

    it 'correctly parses three directories (one repeated) and three files (one repeated from directories and another repeated from files) and returns the unique files' do
      repeats.each { |file| expect(File.file?(file)).to be true }
      expect(repeats.length).to eql(10)
    end
  end

  context '.sort_input_files' do
    it 'correctly sorts an array of files to be checked' do
      PuppetCheck.ignored_files = []
      puppetcheck.sort_input_files(%w(puppet.pp puppet_template.epp ruby.rb ruby_template.erb yaml.yaml yaml.yml json.json Puppetfile Modulefile foobarbaz))
      expect(puppetcheck.instance_variable_get(:@puppet_manifests)).to eql(['puppet.pp'])
      expect(puppetcheck.instance_variable_get(:@puppet_templates)).to eql(['puppet_template.epp'])
      expect(puppetcheck.instance_variable_get(:@ruby_rubies)).to eql(['ruby.rb'])
      expect(puppetcheck.instance_variable_get(:@ruby_templates)).to eql(['ruby_template.erb'])
      expect(puppetcheck.instance_variable_get(:@data_yamls)).to eql(['yaml.yaml', 'yaml.yml'])
      expect(puppetcheck.instance_variable_get(:@data_jsons)).to eql(['json.json'])
      expect(puppetcheck.instance_variable_get(:@ruby_librarians)).to eql(%w(Puppetfile Modulefile))
      expect(PuppetCheck.ignored_files).to eql(['-- foobarbaz'])
    end
  end

  context '.output_results' do
    before(:each) do
      PuppetCheck.error_files = []
      PuppetCheck.warning_files = []
      PuppetCheck.clean_files = []
      PuppetCheck.ignored_files = []
    end

    it 'outputs files with errors' do
      PuppetCheck.error_files = ['-- foo: i had an error']
      expect { PuppetCheck.output_results }.to output("\033[31mThe following files have errors:\033[0m\n-- foo: i had an error\n").to_stdout
    end
    it 'outputs files with warnings' do
      PuppetCheck.warning_files = ['-- foo: i had a warning']
      expect { PuppetCheck.output_results }.to output("\n\033[33mThe following files have warnings:\033[0m\n-- foo: i had a warning\n").to_stdout
    end
    it 'outputs files with no errors or warnings' do
      PuppetCheck.clean_files = ['-- foo: i was totally good to go']
      expect { PuppetCheck.output_results }.to output("\n\033[32mThe following files have no errors or warnings:\033[0m\n-- foo: i was totally good to go\n").to_stdout
    end
    it 'outputs files that were not processed' do
      PuppetCheck.ignored_files = ['-- foo: who knows what i am']
      expect { PuppetCheck.output_results }.to output("\n\033[34mThe following files were unrecognized formats and therefore not processed:\033[0m\n-- foo: who knows what i am\n").to_stdout
    end
  end
end
