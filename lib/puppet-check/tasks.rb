# TODO: RC task has future option

require 'rake'
require 'rake/tasklib'
require_relative '../puppet-check'

# the rake interface for PuppetCheck
class PuppetCheck::Tasks < ::Rake::TaskLib
  def initialize
    desc 'Execute Puppet-Check syntax checks'
    task 'puppetcheck:syntax' do
      PuppetCheck.new.run(Dir.glob('*'))
    end

    desc 'Execute Puppet-Check syntax and style checks'
    task 'puppetcheck:all' do
      require 'puppet-lint/tasks/puppet-lint'
      require 'rubocop/rake_task'
      require 'reek/rake/task' if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.1.0')
      PuppetCheck.new.run(Dir.glob('*'))
    end
  end
end

PuppetCheck::Tasks.new
