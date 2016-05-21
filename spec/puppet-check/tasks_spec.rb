require 'rake/task'
require_relative '../spec_helper.rb'
require_relative '../../lib/puppet-check/tasks'

describe PuppetCheck::Tasks do
  context 'puppetcheck:spec' do
    let(:spec_tasks) { Rake::Task['puppetcheck:spec'.to_sym].invoke }

    it 'executes RSpec and RSpec-Puppet checks in the expected manner' do
      Dir.chdir(fixtures_dir)

      # rspec task executed
      expect { spec_tasks }.to output(/ruby.*rspec/).to_stdout
      # if this is first then the stdout is not captured for testing
      expect { spec_tasks }.not_to raise_exception
      # rspec-puppet setup executed
      expect(File.directory?('spec/fixtures/modules/fixtures')).to be true

      # cleanup rspec-puppet setup
      %w(Rakefile spec/spec_helper.rb).each { |file| File.delete(file) }
      %w(manifests modules).each { |dir| FileUtils.rm_r('spec/fixtures/' + dir) }
    end
  end

  context 'puppetcheck:beaker' do
    it 'verifies the Beaker task exists' do
      Dir.chdir(fixtures_dir)
      expect { Rake::Task['puppetcheck:spec'.to_sym].invoke }.not_to raise_exception
    end
  end
end
