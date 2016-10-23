require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'reek/rake/task'

task default: [:rubocop, :reek, :unit, :system]

RuboCop::RakeTask.new(:rubocop) do |task|
  task.formatters = ['simple']
  task.fail_on_error = false
end

Reek::Rake::Task.new do |task|
  task.fail_on_error = false
end

desc 'Execute unit spec tests'
RSpec::Core::RakeTask.new(:unit) do |task|
  task.pattern = 'spec/{puppet-check_spec.rb, puppet-check/*_spec.rb}'
end

desc 'Execute system spec tests'
RSpec::Core::RakeTask.new(:system) do |task|
  task.pattern = 'spec/system/*_spec.rb'
end
