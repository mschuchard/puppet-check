require 'rake/task'
require_relative '../spec_helper.rb'
require_relative '../../lib/puppet-check/tasks'

describe PuppetCheck::Tasks do
  context 'puppetcheck:spec' do
    let(:spec_tasks) { Rake::Task['puppetcheck:spec'.to_sym].invoke }

    it 'executes RSpec and RSpec-Puppet checks in the expected manner' do
      Dir.chdir(fixtures_dir)

      # rspec task executed
      expect { spec_tasks }.to output(%r{spec/facter/facter_spec.rb}).to_stdout
      # if this is first then the stdout is not captured for testing
      expect { spec_tasks }.not_to raise_exception

      # cleanup rspec_puppet_setup
      %w(spec/spec_helper.rb).each { |file| File.delete(file) }
      %w(manifests modules).each { |dir| FileUtils.rm_r('spec/fixtures/' + dir) }
    end
  end

  context 'puppetcheck:beaker' do
    let(:beaker_tasks) { Rake::Task['puppetcheck:beaker'.to_sym].invoke }

    it 'verifies the Beaker task exists' do
      Dir.chdir(fixtures_dir)

      # beaker task executed
      expect { beaker_tasks }.to output(%r{spec/acceptance}).to_stdout
      expect { beaker_tasks }.not_to raise_exception
    end
  end

  context '.rspec_puppet_setup' do
    let(:rspec_puppet_setup) { PuppetCheck::Tasks.rspec_puppet_setup }
    before(:each) { Dir.chdir(fixtures_dir) }

    it 'creates missing directories, missing site.pp, missing symlinks, and a missing spec_helper' do
      expect { rspec_puppet_setup }.to output("puppetlabs/gruntmaster has an unspecified, or specified but unsupported, download method.\n").to_stderr

      expect(File.directory?('spec/fixtures/manifests')).to be true
      expect(File.directory?('spec/fixtures/modules/fixtures')).to be true
      expect(File.file?('spec/fixtures/manifests/site.pp')).to be true
      expect(File.symlink?('spec/fixtures/modules/fixtures/hieradata')).to be true
      expect(File.symlink?('spec/fixtures/modules/fixtures/manifests')).to be true
      expect(File.symlink?('spec/fixtures/modules/fixtures/lib')).to be true
      expect(File.symlink?('spec/fixtures/modules/fixtures/templates')).to be true
      expect(File.file?('spec/spec_helper.rb')).to be true

      expect(File.directory?('spec/fixtures/modules/puppetlabs-lvm')).to be true
      expect(File.directory?('spec/fixtures/modules/stdlib')).to be true

      # cleanup rspec_puppet_setup
      %w(spec/spec_helper.rb).each { |file| File.delete(file) }
      %w(manifests modules).each { |dir| FileUtils.rm_r('spec/fixtures/' + dir) }
    end
  end
end
