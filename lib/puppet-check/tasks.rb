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
        # generate tasks for all recognized directories and ensure spec tests inside module dependencies are ignored
        spec_dirs = Dir.glob('**/{classes,defines,facter,functions,hosts,puppet,unit,types}/**/*_spec.rb').reject { |dir| dir =~ /fixtures/ }
        task.pattern = spec_dirs.empty? ? 'skip_rspec' : spec_dirs
      end

      desc 'Execute Beaker acceptance tests'
      RSpec::Core::RakeTask.new(:beaker) do |task|
        # generate tasks for all recognized directories and ensure acceptance tests inside module dependencies are ignored
        acceptance_dirs = Dir.glob('**/acceptance').reject { |dir| dir =~ /fixtures/ }
        task.pattern = acceptance_dirs.empty? ? 'skip_beaker' : acceptance_dirs
      end
    end
  end

  # code diagram for rspec-puppet support:
  # puppetcheck:spec task invokes rspec_puppet_setup
  # rspec_puppet_setup invokes rspec_puppet_file_setup always and rspec_puppet_dependency_setup if metadata.json exists
  # rspec_puppet_dependency_setup invokes rspec_puppet_git/forge if git/forge is download option

  # prepare the spec fixtures directory for rspec-puppet testing
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

      # grab the module name from the directory name of the module to pass to rspec_puppet_file_setup
      rspec_puppet_file_setup(File.basename(Dir.pwd))

      # invoke rspec_puppet_dependency_setup for module dependencies if metadata.json present
      rspec_puppet_dependency_setup if File.file?('metadata.json')
    end
  end

  # setup the files, directories, and symlinks for rspec-puppet testing
  def self.rspec_puppet_file_setup(module_name)
    # create all the necessary fixture dirs that are missing
    ['spec/fixtures', 'spec/fixtures/manifests', 'spec/fixtures/modules', "spec/fixtures/modules/#{module_name}"].each do |dir|
      FileUtils.mkdir(dir) unless File.directory?(dir)
    end

    # create empty site.pp if missing
    FileUtils.touch('spec/fixtures/manifests/site.pp') unless File.file?('spec/fixtures/manifests/site.pp')

    # symlink over everything the module needs for compilation
    %w(hiera.yaml data hieradata functions manifests lib files templates).each do |file|
      FileUtils.ln_s("../../../../#{file}", "spec/fixtures/modules/#{module_name}/#{file}") if File.exist?(file) && !File.exist?("spec/fixtures/modules/#{module_name}/#{file}")
    end

    # create spec_helper if missing
    unless File.file?('spec/spec_helper.rb')
      File.open('spec/spec_helper.rb', 'w') { |file| file.puts "require 'rspec-puppet/spec_helper'\n" }
    end
  end

  # setup the module dependencies for rspec-puppet testing
  def self.rspec_puppet_dependency_setup
    # parse the metadata.json (assumes PuppetCheck file checks have already given it a pass)
    parsed = JSON.parse(File.read('metadata.json'))

    # grab dependencies if they exist
    unless parsed['dependencies'].empty?
      parsed['dependencies'].each do |dependency_hash|
        # determine how the user wants to download the module dependency
        if dependency_hash.key?('git')
          puts dependency_hash['name'] + ' uses git'
        elsif dependency_hash.key?('forge')
          puts dependency_hash['name'] + ' uses forge'
        else
          warn "#{dependency_hash['name']} has an unspecified, or specified but unsupported download method."
        end
      end
    end
  end

  # download external module dependency with git
  def self.rspec_puppet_git
    #
  end

  # download external module dependency with forge
  def self.rspec_puppet_forge
    #
  end
end

PuppetCheck::Tasks.new
