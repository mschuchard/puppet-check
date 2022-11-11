require 'rake/task'
require_relative '../spec_helper'
require_relative '../../lib/puppet-check/tasks'

describe PuppetCheck::Tasks do
  after(:all) do
    # cleanup rspec_puppet_setup
    File.delete("#{fixtures_dir}/spec/spec_helper.rb")
    %w[manifests modules].each { |dir| FileUtils.rm_r("#{fixtures_dir}/spec/fixtures/#{dir}") }
  end

  context 'puppetcheck:spec' do
    let(:spec_tasks) { Rake::Task[:'puppetcheck:spec'].invoke }

    it 'executes RSpec and RSpec-Puppet checks in the expected manner' do
      Dir.chdir(fixtures_dir)

      # rspec task executed
      expect { spec_tasks }.to output(%r{spec/facter/facter_spec.rb}).to_stdout
      # if this is first then the stdout is not captured for testing
      expect { spec_tasks }.not_to raise_exception
    end
  end

  context 'puppetcheck:beaker' do
    let(:beaker_task) { Rake::Task[:'puppetcheck:beaker'].invoke }

    it 'verifies the Beaker task exists' do
      Dir.chdir(fixtures_dir)

      # beaker task executed
      expect { beaker_task }.to output("Beaker is not installed. The Beaker tasks will not be available.\n").to_stdout
    end
  end

  context 'puppetcheck:kitchen' do
    let(:kitchen_task) { Rake::Task[:'puppetcheck:kitchen'].invoke }

    it 'verifies the Kitchen task exists' do
      Dir.chdir(fixtures_dir)

      # beaker task executed
      expect { kitchen_task }.to output("Test Kitchen is not installed. The Kitchen tasks will not be available.\n").to_stdout
    end
  end
end
