require_relative '../spec_helper'
require_relative '../../lib/puppet-check/utils'

describe Utils do
  context '.capture_stdout' do
    let(:stdout_test) { Utils.capture_stdout { puts 'hello world' } }

    it 'captures the stdout from a block of code' do
      expect(stdout_test.chomp).to eql('hello world')
    end
  end

  context '.capture_stderr' do
    let(:stderr_test) { Utils.capture_stderr { warn 'hello world' } }

    it 'captures the stderr from a block of code' do
      expect(stderr_test.chomp).to eql('hello world')
    end
  end
end
