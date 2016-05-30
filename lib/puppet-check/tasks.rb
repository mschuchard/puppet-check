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
        self.class.rspec_puppet_setup
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
  def self.rspec_puppet_setup
    # ensure this method does not do anything inside module dependencies
    specdirs = Dir.glob('**/spec').reject { |dir| dir =~ /fixtures/ }
    return if specdirs.class.to_s == 'NilClass'

    # setup fixtures for rspec-puppet testing
    specdirs.each do |specdir|
      # skip to next specdir if it does not seem like a puppet module
      next unless File.directory?(specdir + '/../manifests')

      # move up to module directory
      Dir.chdir(specdir + '/..')

      # grab the module name from the directory name of the module
      module_name = File.basename(Dir.pwd)

      # create all the necessary fixture dirs that are missing
      ['spec/fixtures', 'spec/fixtures/manifests', 'spec/fixtures/modules', "spec/fixtures/modules/#{module_name}"].each do |dir|
        FileUtils.mkdir(dir) unless File.directory?(dir)
      end

      # create empty site.pp if missing
      FileUtils.touch('spec/fixtures/manifests/site.pp') unless File.file?('spec/fixtures/manifests/site.pp')

      # symlink over everything the module needs for compilation
      %w(hiera.yaml data hieradata functions manifests lib files templates).each do |file|
        FileUtils.ln_s("../../../../#{file}", "spec/fixtures/modules/#{module_name}/#{file}") if File.exist?(file)
      end

      # create spec_helper if missing
      next if File.file?('spec/spec_helper.rb')
      File.open('spec/spec_helper.rb', 'w') do |file|
        file.puts "require 'rspec-puppet/spec_helper'\n"
      end
    end
  end
end

PuppetCheck::Tasks.new
