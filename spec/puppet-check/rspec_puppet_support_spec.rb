require_relative '../spec_helper'
require_relative '../../lib/puppet-check/rspec_puppet_support'
require 'fileutils'

describe RSpecPuppetSupport do
  after(:all) do
    # cleanup rspec_puppet_setup
    File.delete('spec/spec_helper.rb')
    %w[manifests modules].each { |dir| FileUtils.rm_r('spec/fixtures/' + dir) }
  end

  context '.run' do
    let(:rspec_puppet_setup) { RSpecPuppetSupport.run }
    before(:each) { Dir.chdir(fixtures_dir) }

    it 'creates missing directories, missing site.pp, missing symlinks, and a missing spec_helper' do
      # travis ci
      if ENV['TRAVIS'] == true
        expect { rspec_puppet_setup }.to output("puppetlabs/gruntmaster has an unspecified, or specified but unsupported, download method.\n").to_stderr
      # circle ci
      elsif ENV['CIRCLECI'] == true
        expect { rspec_puppet_setup }.to output("git is not installed and cannot be used to retrieve dependency modules\nsubversion is not installed and cannot be used to retrieve dependency modules\npuppetlabs/gruntmaster has an unspecified, or specified but unsupported, download method.\n").to_stderr
      else
        expect { rspec_puppet_setup }.to output("subversion is not installed and cannot be used to retrieve dependency modules\npuppetlabs/gruntmaster has an unspecified, or specified but unsupported, download method.\n").to_stderr
      end

      # .file_setup
      expect(File.directory?('spec/fixtures/manifests')).to be true
      expect(File.directory?('spec/fixtures/modules')).to be true
      expect(File.file?('spec/fixtures/manifests/site.pp')).to be true
      expect(File.symlink?('spec/fixtures/modules/fixtures')).to be true
      expect(File.file?('spec/spec_helper.rb')).to be true

      # .dependency_setup
      expect(File.directory?('spec/fixtures/modules/puppetlabs-lvm')).to be true
      expect(File.directory?('spec/fixtures/modules/stdlib')).to be true
    end
  end
end
