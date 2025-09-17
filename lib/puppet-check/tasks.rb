begin
  require 'rake/tasklib'
rescue LoadError
  raise 'Rake is not installed and you are attempting to execute Rake tasks with Puppet Check. Please install Rake before continuing.'
end
require_relative '../puppet_check'

# the rake interface for PuppetCheck
class PuppetCheck::Tasks < Rake::TaskLib
  def initialize
    super

    desc 'Execute all Puppet-Check checks'
    task puppetcheck: %w[puppetcheck:file puppetcheck:spec puppetcheck:beaker puppetcheck:kitchen]

    namespace :puppetcheck do
      desc 'Execute Puppet-Check file checks'
      task :file, [:settings] do |_, wrapped_settings|
        wrapped_settings = wrapped_settings[:settings] || {}
        PuppetCheck.new.run(wrapped_settings, Dir.glob('*'))
      end

      # rspec and rspec-puppet tasks
      begin
        require 'rspec/core/rake_task'
        require_relative 'rspec_puppet_support'

        desc 'Execute RSpec and RSpec-Puppet tests'
        RSpec::Core::RakeTask.new(:spec) do |task|
          RSpecPuppetSupport.run
          # generate tasks for all recognized directories and ensure spec tests inside module dependencies are ignored
          spec_dirs = Dir.glob('**/{classes,defines,facter,functions,hosts,puppet,unit,types}/**/*_spec.rb').grep_v(/fixtures/)
          task.pattern = spec_dirs.empty? ? 'skip_rspec' : spec_dirs
        end
      rescue LoadError
        desc 'RSpec is not installed.'
        task :spec do
          puts 'RSpec is not installed. The RSpec/RSpec-Puppet tasks will not be available.'
        end
      end

      # beaker tasks
      begin
        require 'beaker/tasks/quick_start'

        desc 'Execute Beaker acceptance tests'
        task :beaker, %i[hypervisor] do |_, args|
          args[:hypervisor] = 'vagrant' if args[:hypervisor].nil?
          Rake::Task["beaker_quickstart:run_test[#{args[:hypervisor]}]"].invoke
        end
      rescue LoadError
        desc 'Beaker is not installed.'
        task :beaker do
          puts 'Beaker is not installed. The Beaker tasks will not be available.'
        end
      end

      # test kitchen tasks
      begin
        require 'kitchen/rake_tasks'

        desc 'Execute Test Kitchen acceptance tests'
        task :kitchen do
          Rake::Task['kitchen:all'].invoke
        end
      rescue LoadError
        desc 'Test Kitchen is not installed.'
        task :kitchen do
          puts 'Test Kitchen is not installed. The Kitchen tasks will not be available.'
        end
      end
    end
  end
end

PuppetCheck::Tasks.new
