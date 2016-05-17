require 'rspec/core/rake_task'
require 'rake/tasklib'
require_relative '../puppet-check'

# the rake interface for PuppetCheck
class PuppetCheck::Tasks < ::Rake::TaskLib
  def initialize
    desc 'Execute all Puppet-Check checks'
    task :puppetcheck do
      ['puppetcheck:file'.to_sym, 'puppetcheck:spec'.to_sym].each { |task| system("#{ENV['_']} #{task}") {} }
    end

    namespace :puppetcheck do
      desc 'Execute Puppet-Check file checks'
      task :file do
        exit PuppetCheck.new.run(Dir.glob('*'))
      end

      desc 'Execute Puppet-Check spec checks'
      RSpec::Core::RakeTask.new(:spec) do |task|
        # generate tasks for all recognized directories inside of spec directories
        task.pattern = '**/{classes, defines, facter, functions, hosts, puppet, unit, types}/**/*_spec.rb'
      end
    end
  end
end

PuppetCheck::Tasks.new
