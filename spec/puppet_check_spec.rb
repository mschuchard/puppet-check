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
      expect(PuppetCheck.send(:defaults)).to eql(
        {
          fail_on_warnings: false,
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
        fail_on_warnings: true,
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
      expect(PuppetCheck.send(:defaults, settings)).to eql(settings)
    end
  end

  context '.parse_paths' do
    before(:each) { Dir.chdir(FIXTURES_DIR) }

    let(:no_files) { PuppetCheck.send(:parse_paths, %w[foo bar baz]) }
    let(:mixed_files) { PuppetCheck.send(:parse_paths, %w[foo lib/good.rb]) }
    let(:file) { PuppetCheck.send(:parse_paths, ['lib/good.rb']) }
    let(:dir) { PuppetCheck.send(:parse_paths, ['.']) }
    let(:multi_dir) { PuppetCheck.send(:parse_paths, %w[hieradata lib manifests]) }
    let(:repeats) { PuppetCheck.send(:parse_paths, ['hieradata', 'hieradata', 'lib', 'hieradata/good.json', 'manifests/good.pp', 'manifests/good.pp']) }

    it 'raises an error if no files were found' do
      expect { no_files }.to raise_error(RuntimeError, 'puppet-check: no files found in supplied paths \'foo, bar, baz\'.')
    end

    it 'warns on invalid path and correctly parses a valid file path' do
      expect { mixed_files }.to output("puppet-check: foo is not a readable directory, file, or symlink, and will not be considered during parsing\n").to_stderr
      expect(mixed_files[0]).to eql('lib/good.rb')
    end

    it 'correctly parses one file and returns it' do
      expect(file[0]).to eql('lib/good.rb')
    end

    it 'correctly parses one directory and returns all of its files' do
      dir.each { |file| expect(File.file?(file)).to be true }
      if CI_ENV
        expect(dir.length).to eql(37)
      else
        expect(dir.length).to eql(40)
      end
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
    before(:each) do
      PuppetCheck.files = { errors: {}, warnings: {}, clean: [], ignored: [] }
    end
    let(:puppet_check) { PuppetCheck.new }

    it 'correctly routes each file type to the appropriate parser and ignores unrecognized files' do
      expect(PuppetParser).to receive(:manifest).with(['manifests/good.pp'], false, [])
      expect(PuppetParser).to receive(:template).with(['templates/good.epp'])
      expect(RubyParser).to receive(:ruby).with(['lib/good.rb'], false, [])
      expect(RubyParser).to receive(:template).with(['templates/good.erb'])
      expect(DataParser).to receive(:yaml).with(['hieradata/good.yaml', 'hieradata/good.yml'])
      expect(DataParser).to receive(:json).with(['hieradata/good.json'])
      expect(DataParser).to receive(:eyaml).with(['hieradata/good.eyaml'], nil, nil)
      expect(RubyParser).to receive(:librarian).with(['librarian/Puppetfile_good'], false, [])

      puppet_check.send(:execute_parsers, %w[manifests/good.pp templates/good.epp lib/good.rb templates/good.erb hieradata/good.yaml hieradata/good.yml hieradata/good.json hieradata/good.eyaml librarian/Puppetfile_good foobarbaz], false, [], [], nil, nil)

      expect(PuppetCheck.files[:ignored]).to eql(['foobarbaz'])
    end

    it 'passes style and arg options through to the correct parsers and skips parser calls when a given file category is empty' do
      expect(PuppetParser).to receive(:manifest).with(['manifests/good.pp'], true, ['--no-140chars-check'])
      expect(PuppetParser).not_to receive(:template)
      expect(RubyParser).to receive(:ruby).with(['lib/good.rb'], true, ['--except', 'Style/FrozenStringLiteralComment'])
      expect(RubyParser).to receive(:librarian).with(['librarian/Puppetfile_good'], true, ['--except', 'Style/FrozenStringLiteralComment'])
      expect(RubyParser).not_to receive(:template)
      expect(DataParser).to receive(:yaml).with(['hieradata/good.yaml'])
      expect(DataParser).not_to receive(:json)
      expect(DataParser).not_to receive(:eyaml)

      puppet_check.send(
        :execute_parsers,
        %w[manifests/good.pp lib/good.rb hieradata/good.yaml librarian/Puppetfile_good],
        true,
        ['--no-140chars-check'],
        ['--except', 'Style/FrozenStringLiteralComment'],
        nil,
        nil
      )
    end

    it 'returns PuppetCheck.files' do
      allow(PuppetParser).to receive(:manifest)
      result = puppet_check.send(:execute_parsers, ['manifests/good.pp'], false, [], [], nil, nil)
      expect(result).to eql(PuppetCheck.files)
    end
  end
end
