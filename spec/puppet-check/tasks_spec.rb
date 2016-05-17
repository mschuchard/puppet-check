require 'rake'
require_relative '../spec_helper.rb'
require_relative '../../lib/puppet-check/tasks'

describe PuppetCheck::Tasks do
  context 'puppetcheck:spec' do
    let(:spec_tasks) { Rake::Task['puppetcheck:spec'.to_sym].invoke }

    before(:each) { Dir.chdir(fixtures_dir) }

    it 'executes RSpec and RSpec-Puppet checks in the expected manner' do
      expect { spec_tasks }.to output(/ruby.*rspec/).to_stdout
    end
  end
end
