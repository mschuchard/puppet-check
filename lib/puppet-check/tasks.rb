require 'rspec/core/rake_task'
require 'rake/tasklib'
require 'rake/task'
require_relative '../puppet-check'

# the rake interface for PuppetCheck
class PuppetCheck::Tasks < ::Rake::TaskLib
  def initialize
    desc 'Execute all Puppet-Check checks'
    task :puppetcheck do
      %w(puppetcheck:file puppetcheck:spec puppetcheck:beaker).each { |task| Rake::Task[task.to_sym].invoke }
    end

    namespace :puppetcheck do
      desc 'Execute Puppet-Check file checks'
      task :file do
        exit_code = PuppetCheck.new.run(Dir.glob('*'))
        # changes nothing if this task is run separately; aborts 'puppetcheck' task if there are errors here
        exit exit_code if exit_code != 0
      end

      desc 'Execute RSpec and RSpec-Puppet tests'
      RSpec::Core::RakeTask.new(:spec) do |task|
        rspec_puppet_setup
        # generate tasks for all recognized directories
        task.pattern = '**/{classes, defines, facter, functions, hosts, puppet, unit, types}/**/*_spec.rb'
      end

      desc 'Execute Beaker acceptance tests'
      RSpec::Core::RakeTask.new(:beaker) do |task|
        task.pattern = '**/acceptance'
      end
    end
  end

  # prepare the directories for rspec-puppet testing
  def rspec_puppet_setup
    # leave method immediately if there is no rspec-puppet installed
    begin
      require 'rspec-puppet/setup'
    rescue LoadError
      return
    end

    # executes rspec::puppet::setup in every module directory to ensure module spec directories are configured correctly
    # ensure this method does not do anything inside module dependencies
    specdirs = Dir.glob('**/spec').reject! { |dir| dir =~ /fixtures/ }
    specdirs.each do |specdir|
      Dir.chdir(specdir + '/..')
      RSpec::Puppet::Setup.run
    end
  end
end

PuppetCheck::Tasks.new
