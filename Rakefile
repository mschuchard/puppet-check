require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'reek/rake/task' if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.1.0')

task default: [:rubocop, :reek, :spec]

RuboCop::RakeTask.new(:rubocop) do |task|
  task.formatters = ['simple']
  task.fail_on_error = false
end

if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.1.0')
  Reek::Rake::Task.new do |task|
    task.fail_on_error = false
  end
end

RSpec::Core::RakeTask.new(:spec)
