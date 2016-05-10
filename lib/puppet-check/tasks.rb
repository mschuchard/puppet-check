require 'rake'
require 'rake/tasklib'
require_relative '../puppet-check'

# the rake interface for PuppetCheck
class PuppetCheck::Tasks < ::Rake::TaskLib
  def initialize
    desc 'Execute Puppet-Check file checks'
    task 'puppetcheck:file' do
      PuppetCheck.new.run(Dir.glob('*'))
    end
  end
end

PuppetCheck::Tasks.new
