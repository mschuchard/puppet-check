require_relative '../spec_helper.rb'
require_relative '../../lib/puppet-check/rspec_puppet_support'
require 'fileutils'

describe RSpecPuppetSupport do
  context '.run' do
    let(:rspec_puppet_setup) { RSpecPuppetSupport.run }
    before(:each) { Dir.chdir(fixtures_dir) }

    it 'creates missing directories, missing site.pp, missing symlinks, and a missing spec_helper' do
      expect { rspec_puppet_setup }.to output("puppetlabs/gruntmaster has an unspecified, or specified but unsupported, download method.\n").to_stderr

      # .file_setup
      expect(File.directory?('spec/fixtures/manifests')).to be true
      expect(File.directory?('spec/fixtures/modules/fixtures')).to be true
      expect(File.file?('spec/fixtures/manifests/site.pp')).to be true
      expect(File.symlink?('spec/fixtures/modules/fixtures/hieradata')).to be true
      expect(File.symlink?('spec/fixtures/modules/fixtures/manifests')).to be true
      expect(File.symlink?('spec/fixtures/modules/fixtures/lib')).to be true
      expect(File.symlink?('spec/fixtures/modules/fixtures/templates')).to be true
      expect(File.file?('spec/spec_helper.rb')).to be true

      # .dependency_setup
      expect(File.directory?('spec/fixtures/modules/puppetlabs-lvm')).to be true
      expect(File.directory?('spec/fixtures/modules/stdlib')).to be true

      # cleanup rspec_puppet_setup
      %w[spec/spec_helper.rb].each { |file| File.delete(file) }
      %w[manifests modules].each { |dir| FileUtils.rm_r('spec/fixtures/' + dir) }
    end
  end
end
