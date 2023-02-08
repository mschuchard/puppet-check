require_relative 'spec_helper'
require_relative '../lib/puppet_check'

describe PuppetCheck do
  context 'self' do
    it 'files are initialized correctly' do
      expect(PuppetCheck.files).to eql(
        {
          errors: {},
          warnings: {},
          clean: [],
          ignored: []
        }
      )
    end
    it 'files can be altered' do
      PuppetCheck.files = {
        errors: { 'foo' => ['i had an error'] },
        warnings: { 'foo' => ['i had a warning'] },
        clean: ['foo'],
        ignored: ['foo']
      }
      expect(PuppetCheck.files).to eql(
        {
          errors: { 'foo' => ['i had an error'] },
          warnings: { 'foo' => ['i had a warning'] },
          clean: ['foo'],
          ignored: ['foo']
        }
      )
    end
  end

  context 'defaults' do
    it 'returns defaults correctly' do
      expect(PuppetCheck.defaults).to eql(
        {
          fail_on_warning: false,
          style: false,
          smoke: false,
          regression: false,
          public: nil,
          private: nil,
          output_format: 'text',
          octoconfig: '.octocatalog-diff.cfg.rb',
          octonodes: %w[localhost.localdomain],
          puppetlint_args: [],
          rubocop_args: []
        }
      )
    end

    it 'modifies settings correctly' do
      settings = {
        fail_on_warning: true,
        style: true,
        smoke: true,
        regression: true,
        public: 'public.pem',
        private: 'private.pem',
        output_format: 'yaml',
        octoconfig: '.octocatalog-diff.cfg.erb',
        octonodes: %w[host.domain],
        puppetlint_args: %w[--puppetlint-arg-one --puppetlint-arg-two],
        rubocop_args: %w[--rubocop-arg-one --rubocop-arg-two]
      }
      expect(PuppetCheck.defaults(settings)).to eql(settings)
    end
  end

  context '.parse_paths' do
    before(:each) { Dir.chdir(fixtures_dir) }

    let(:no_files) { PuppetCheck.parse_paths(%w[foo bar baz]) }
    let(:file) { PuppetCheck.parse_paths(['lib/good.rb']) }
    let(:dir) { PuppetCheck.parse_paths(['.']) }
    let(:multi_dir) { PuppetCheck.parse_paths(%w[hieradata lib manifests]) }
    let(:repeats) { PuppetCheck.parse_paths(['hieradata', 'hieradata', 'lib', 'hieradata/good.json', 'manifests/good.pp', 'manifests/good.pp']) }

    it 'raises an error if no files were found' do
      expect { no_files }.to raise_error(RuntimeError, 'puppet-check: no files found in supplied paths \'foo, bar, baz\'.')
    end

    it 'correctly parses one file and returns it' do
      expect(file[0]).to eql('lib/good.rb')
    end

    it 'correctly parses one directory and returns all of its files' do
      dir.each { |file| expect(File.file?(file)).to be true }
      expect(dir.length).to eql(37)
    end

    it 'correctly parses multiple directories and returns all of their files' do
      multi_dir.each { |file| expect(File.file?(file)).to be true }
      expect(multi_dir.length).to eql(17)
    end

    it 'correctly parses three directories (one repeated) and three files (one repeated from directories and another repeated from files) and returns the unique files' do
      repeats.each { |file| expect(File.file?(file)).to be true }
      expect(repeats.length).to eql(13)
    end
  end

  context '.execute_parsers' do
    it 'correctly organizes a set of files and invokes the correct parsers' do
      # parser_output = instance_double('execute_parsers', files: %w[puppet.pp puppet_template.epp ruby.rb ruby_template.erb yaml.yaml yaml.yml json.json Puppetfile Modulefile foobarbaz], style: false, pl_args: [], rc_args: [])
      # expect(parser_output).to receive(:manifest).with(%w[puppet.pp])
      # expect(parser_output).to receive(:template).with(%w[puppet_template.epp])
      # expect(parser_output).to receive(:ruby).with(%w[ruby.rb])
      # expect(parser_output).to receive(:template).with(%w[ruby_template.erb])
      # expect(parser_output).to receive(:yaml).with(%w[yaml.yaml yaml.yml])
      # expect(parser_output).to receive(:json).with(%w[json.json])
      # expect(parser_output).to receive(:librarian).with(%w[Puppetfile Modulefile])
      # expect(PuppetCheck.files[:ignored]).to eql(%w[foobarbaz])
    end
  end
end
