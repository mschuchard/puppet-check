# TODO: 1.1 add in rspec, rspec puppet, and beaker as optional tasks (begin, require gem, rescue)
# TODO: RC task has style/future options
# TODO: RC args for style options
# TODO: RC verbose logging eventually
# TODO: RC add ARG parser method that assigns user options

require 'rake'
require 'rake/tasklib'
require_relative '../puppet-check'

# the rake interface for PuppetCheck
class PuppetCheck::Tasks < ::Rake::TaskLib
  def initialize
    desc 'Execute Puppet-Check'
    task 'PuppetCheck' do
      PuppetCheck.new.run(Dir.glob('*'))
    end
  end
end

PuppetCheck::Tasks.new
