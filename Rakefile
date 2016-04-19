require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'reek/rake/task'

task default: [:rubocop, :reek, :spec]

RuboCop::RakeTask.new(:rubocop) do |task|
  task.formatters = ['simple']
  task.fail_on_error = false
end

Reek::Rake::Task.new do |task|
  task.fail_on_error = false
end

RSpec::Core::RakeTask.new(:spec)
