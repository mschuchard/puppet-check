require_relative 'spec_helper'
require_relative '../lib/puppet-check'

describe PuppetCheck do
  let(:puppetcheck) { PuppetCheck.new([], [], []) }

  context 'initializes and' do
    it 'args, future parser, style check, puppet-lint args, rubocop args, and reek args have the correct defaults' do
      # this becomes true due to other tests executing before this one so reset the default assignment
      PuppetCheck.style_check = false
      expect(PuppetCheck.future_parser).to eql(false)
      expect(PuppetCheck.style_check).to eql(false)
      expect(puppetcheck.instance_variable_get(:@puppetlint_args)).to eql([])
      expect(puppetcheck.instance_variable_get(:@rubocop_args)).to eql([])
      expect(puppetcheck.instance_variable_get(:@reek_args)).to eql([])
    end
    it 'future parser can be altered' do
      PuppetCheck.future_parser = true
      expect(PuppetCheck.future_parser).to eql(true)
    end
    it 'style check can be altered' do
      PuppetCheck.style_check = true
      expect(PuppetCheck.style_check).to eql(true)
    end
    it 'puppet lint arguments can be altered' do
      puppetcheck.instance_variable_set(:@puppetlint_args, ['--puppetlint-arg-one, --puppetlint-arg-two'])
      expect(puppetcheck.instance_variable_get(:@puppetlint_args)).to eql(['--puppetlint-arg-one, --puppetlint-arg-two'])
    end
    it 'rubocop arguments can be altered' do
      puppetcheck.instance_variable_set(:@rubocop_args, ['--rubocop-arg-one, --rubocop-arg-two'])
      expect(puppetcheck.instance_variable_get(:@rubocop_args)).to eql(['--rubocop-arg-one, --rubocop-arg-two'])
    end
    it 'reek arguments can be altered' do
      puppetcheck.instance_variable_set(:@reek_args, ['--reek-arg-one, --reek-arg-two'])
      expect(puppetcheck.instance_variable_get(:@reek_args)).to eql(['--reek-arg-one, --reek-arg-two'])
    end
  end

  context '.parse_paths' do
    it 'correctly parses one file and returns it' do
      puppetcheck.parse_paths([fixtures_dir + 'lib/good.rb'])
      expect(puppetcheck.instance_variable_get(:@all_files)[0]).to match(%r{spec/fixtures/lib/good.rb})
    end

    it 'correctly parses one directory and returns all of its files' do
      puppetcheck.parse_paths([fixtures_dir])
      puppetcheck.instance_variable_get(:@all_files).each { |file| expect(File.file?(file)).to be true }
      expect(puppetcheck.instance_variable_get(:@all_files).length).to eql(18)
    end

    it 'correctly parses multiple directories and returns all of their files' do
      puppetcheck.parse_paths([fixtures_dir + 'hieradata', fixtures_dir + 'lib', fixtures_dir + 'manifests'])
      puppetcheck.instance_variable_get(:@all_files).each { |file| expect(File.file?(file)).to be true }
      expect(puppetcheck.instance_variable_get(:@all_files).length).to eql(10)
    end

    it 'correctly parses three directories (one repeated) and three files (one repeated from directories and another repeated from files) and returns the unique files' do
      puppetcheck.parse_paths([fixtures_dir + 'hieradata', fixtures_dir + 'hieradata', fixtures_dir + 'lib', fixtures_dir + 'hieradata/good.json', fixtures_dir + 'manifests/good.pp', fixtures_dir + 'manifests/good.pp'])
      puppetcheck.instance_variable_get(:@all_files).each { |file| expect(File.file?(file)).to be true }
      expect(puppetcheck.instance_variable_get(:@all_files).length).to eql(8)
    end
  end

  context '.sort_input_files' do
    it 'correctly sorts an array of files to be checked' do
      puppetcheck.sort_input_files(%w(puppet.pp puppet_template.epp ruby.rb ruby_template.erb yaml.yaml yaml.yml json.json Puppetfile Modulefile foobarbaz))
      expect(puppetcheck.instance_variable_get(:@puppet_manifests)).to eql(['puppet.pp'])
      expect(puppetcheck.instance_variable_get(:@puppet_templates)).to eql(['puppet_template.epp'])
      expect(puppetcheck.instance_variable_get(:@ruby_rubies)).to eql(['ruby.rb'])
      expect(puppetcheck.instance_variable_get(:@ruby_templates)).to eql(['ruby_template.erb'])
      expect(puppetcheck.instance_variable_get(:@data_yamls)).to eql(['yaml.yaml', 'yaml.yml'])
      expect(puppetcheck.instance_variable_get(:@data_jsons)).to eql(['json.json'])
      expect(puppetcheck.instance_variable_get(:@ruby_librarians)).to eql(%w(Puppetfile Modulefile))
      expect(PuppetCheck.ignored_files).to eql(['foobarbaz'])
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
      expect { puppetcheck.output_results }.to output("The following files have errors:\n-- foo: i had an error\n").to_stdout
    end
    it 'outputs files with warnings' do
      PuppetCheck.warning_files = ['-- foo: i had a warning']
      expect { puppetcheck.output_results }.to output("The following files have warnings:\n-- foo: i had a warning\n").to_stdout
    end
    it 'outputs files with no errors or warnings' do
      PuppetCheck.clean_files = ['-- foo: i was totally good to go']
      expect { puppetcheck.output_results }.to output("The following files processed with no errors or warnings:\n-- foo: i was totally good to go\n").to_stdout
    end
    it 'outputs files that were not processed' do
      PuppetCheck.ignored_files = ['-- foo: who knows what i am']
      expect { puppetcheck.output_results }.to output("The following files were unrecognized formats and therefore not processed:\n-- foo: who knows what i am\n").to_stdout
    end
  end
end
