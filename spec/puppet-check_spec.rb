require_relative 'spec_helper'
require_relative '../lib/puppet-check'

describe PuppetCheck do
  context 'self' do
    it 'settings can be altered' do
      PuppetCheck.future_parser = true
      expect(PuppetCheck.future_parser).to eql(true)
      PuppetCheck.style_check = true
      expect(PuppetCheck.style_check).to eql(true)
      PuppetCheck.smoke_check = true
      expect(PuppetCheck.smoke_check).to eql(true)
      PuppetCheck.regression_check = true
      expect(PuppetCheck.regression_check).to eql(true)
      PuppetCheck.output_format = 'text'
      expect(PuppetCheck.output_format).to eql('text')
      PuppetCheck.octoconfig = '.octocatalog-diff.cfg.rb'
      expect(PuppetCheck.octoconfig).to eql('.octocatalog-diff.cfg.rb')
      PuppetCheck.octonodes = %w(localhost.localdomain)
      expect(PuppetCheck.octonodes).to eql(%w(localhost.localdomain))
      PuppetCheck.puppetlint_args = ['--puppetlint-arg-one', '--puppetlint-arg-two']
      expect(PuppetCheck.puppetlint_args).to eql(['--puppetlint-arg-one', '--puppetlint-arg-two'])
      PuppetCheck.rubocop_args = ['--rubocop-arg-one', '--rubocop-arg-two']
      expect(PuppetCheck.rubocop_args).to eql(['--rubocop-arg-one', '--rubocop-arg-two'])
    end
  end

  context '.parse_paths' do
    before(:each) { Dir.chdir(fixtures_dir) }

    let(:no_files) { PuppetCheck.parse_paths(%w(foo bar baz)) }
    let(:file) { PuppetCheck.parse_paths(['lib/good.rb']) }
    let(:dir) { PuppetCheck.parse_paths(['.']) }
    let(:multi_dir) { PuppetCheck.parse_paths(%w(hieradata lib manifests)) }
    let(:repeats) { PuppetCheck.parse_paths(['hieradata', 'hieradata', 'lib', 'hieradata/good.json', 'manifests/good.pp', 'manifests/good.pp']) }

    it 'raises an error if no files were found' do
      expect { no_files }.to raise_error(RuntimeError, 'puppet-check: no files found in supplied paths foo, bar, baz.')
    end

    it 'correctly parses one file and returns it' do
      expect(file[0]).to eql('lib/good.rb')
    end

    it 'correctly parses one directory and returns all of its files' do
      dir.each { |file| expect(File.file?(file)).to be true }
      expect(dir.length).to eql(31)
    end

    it 'correctly parses multiple directories and returns all of their files' do
      multi_dir.each { |file| expect(File.file?(file)).to be true }
      expect(multi_dir.length).to eql(14)
    end

    it 'correctly parses three directories (one repeated) and three files (one repeated from directories and another repeated from files) and returns the unique files' do
      repeats.each { |file| expect(File.file?(file)).to be true }
      expect(repeats.length).to eql(10)
    end
  end

  context '.execute_parsers' do
    #
  end
end
