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
      PuppetCheck.style_check = true
      PuppetCheck.new.run(Dir.glob('*'))
    end
  end
end

PuppetCheck::Tasks.new
