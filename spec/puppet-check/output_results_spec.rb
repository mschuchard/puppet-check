require_relative '../spec_helper'
require_relative '../../lib/puppet-check/output_results'
require_relative '../../lib/puppet-check/utils'
require 'rexml/document'
require 'stringio'

describe OutputResults do
  context '.text' do
    it 'outputs files with errors' do
      files = { errors: { 'foo' => ['i had an error'] } }
      expect { OutputResults.send(:text, files) }.to output("\033[31mThe following files have errors:\033[0m\n-- foo:\ni had an error\n\n").to_stdout
    end
    it 'outputs files with warnings' do
      files = { warnings: { 'foo' => ['i had a warning'] } }
      expect { OutputResults.send(:text, files) }.to output("\033[33mThe following files have warnings:\033[0m\n-- foo:\ni had a warning\n\n").to_stdout
    end
    it 'outputs files with no errors or warnings' do
      files = { clean: ['foo'] }
      expect { OutputResults.send(:text, files) }.to output("\033[32mThe following files have no errors or warnings:\033[0m\n-- foo\n\n").to_stdout
    end
    it 'outputs files that were not processed' do
      files = { ignored: ['foo'] }
      expect { OutputResults.send(:text, files) }.to output("\033[36mThe following files have unrecognized formats and therefore were not processed:\033[0m\n-- foo\n\n").to_stdout
    end
  end

  context '.junit' do
    it 'outputs an xml declaration followed by a single test suite document' do
      xml = Utils.capture_stdout { OutputResults.send(:junit, { clean: ['foo'] }) }
      document = REXML::Document.new(xml)

      expect(xml).to start_with("<?xml version='1.0' encoding='UTF-8'?>")
      expect(document.root.name).to eq('testsuite')
      expect(document.root.attributes['name']).to eq('puppet-check')
    end
    it 'outputs files with errors as failures' do
      files = { errors: { 'foo' => ['i had an error'] } }
      suite = REXML::Document.new(Utils.capture_stdout { OutputResults.send(:junit, files) }).root
      testcase = suite.elements['testcase']
      failure = testcase.elements['failure']

      expect(%w[tests failures skipped].map { |name| suite.attributes[name] }).to eq(%w[1 1 0])
      expect(testcase.attributes['classname']).to eq('puppet-check')
      expect(testcase.attributes['name']).to eq('foo')
      expect(failure.attributes['message']).to eq('i had an error')
      expect(failure.text).to eq('i had an error')
    end
    it 'outputs the first error message as the failure message and all error messages as the failure body' do
      files = { errors: { 'foo' => ['i had an error', 'i had another error'] } }
      failure = REXML::Document.new(Utils.capture_stdout { OutputResults.send(:junit, files) }).root.elements['testcase/failure']

      expect(failure.attributes['message']).to eq('i had an error')
      expect(failure.text).to eq("i had an error\ni had another error")
    end
    it 'outputs files with warnings as passing tests with system output' do
      files = { warnings: { 'foo' => ['i had a warning'] } }
      suite = REXML::Document.new(Utils.capture_stdout { OutputResults.send(:junit, files) }).root
      testcase = suite.elements['testcase']

      expect(%w[tests failures skipped].map { |name| suite.attributes[name] }).to eq(%w[1 0 0])
      expect(testcase.attributes['name']).to eq('foo')
      expect(testcase.elements['failure']).to be_nil
      expect(testcase.elements['system-out'].text).to eq('i had a warning')
    end
    it 'outputs files with no errors or warnings as passing tests' do
      files = { clean: ['foo'] }
      suite = REXML::Document.new(Utils.capture_stdout { OutputResults.send(:junit, files) }).root
      testcase = suite.elements['testcase']

      expect(%w[tests failures skipped].map { |name| suite.attributes[name] }).to eq(%w[1 0 0])
      expect(testcase.attributes['name']).to eq('foo')
      expect(testcase.elements).to be_empty
    end
    it 'outputs files that were not processed as skipped tests' do
      files = { ignored: ['foo'] }
      suite = REXML::Document.new(Utils.capture_stdout { OutputResults.send(:junit, files) }).root
      testcase = suite.elements['testcase']

      expect(%w[tests failures skipped].map { |name| suite.attributes[name] }).to eq(%w[1 0 1])
      expect(testcase.attributes['name']).to eq('foo')
      expect(testcase.elements['skipped']).not_to be_nil
    end
    it 'outputs well-formed xml where file names and messages round-trip through a parser' do
      files = { errors: { 'a&b<c>.pp' => ['say "hi" & <bye>', "second 'line'"] } }
      testcase = REXML::Document.new(Utils.capture_stdout { OutputResults.send(:junit, files) }).root.elements['testcase']
      failure = testcase.elements['failure']

      expect(testcase.attributes['name']).to eq('a&b<c>.pp')
      expect(failure.attributes['message']).to eq('say "hi" & <bye>')
      expect(failure.text).to eq("say \"hi\" & <bye>\nsecond 'line'")
    end
    it 'outputs all four file categories in order with accurate suite counts' do
      files = { errors: { 'foo' => ['i had an error'], 'bar' => ['i had another error'] }, warnings: { 'baz' => ['i had a warning'] }, clean: ['qux'], ignored: %w[quux corge] }
      suite = REXML::Document.new(Utils.capture_stdout { OutputResults.send(:junit, files) }).root

      expect(suite.elements.to_a('testcase').map { |testcase| testcase.attributes['name'] }).to eq(%w[foo bar baz qux quux corge])
      expect(%w[tests failures skipped].map { |name| suite.attributes[name] }).to eq(%w[6 2 2])
      expect(suite.elements.to_a('testcase/failure').length).to eq(2)
      expect(suite.elements.to_a('testcase/skipped').length).to eq(2)
    end
    it 'outputs an empty test suite when there are no files' do
      suite = REXML::Document.new(Utils.capture_stdout { OutputResults.send(:junit, {}) }).root

      expect(%w[tests failures skipped].map { |name| suite.attributes[name] }).to eq(%w[0 0 0])
      expect(suite.elements.to_a('testcase')).to be_empty
    end
  end

  context '.run' do
    it 'redirects to text output formatting as expected' do
      expect { OutputResults.run({}, 'text') }.to output('').to_stdout
    end
    it 'outputs files with errors as yaml' do
      files = { errors: { 'foo' => ['i had an error'] } }
      expect { OutputResults.run(files, 'yaml') }.to output("---\nerrors:\n  foo:\n  - i had an error\n").to_stdout
    end
    it 'outputs files with warnings as yaml' do
      files = { warnings: { 'foo' => ['i had a warning'] } }
      expect { OutputResults.run(files, 'yaml') }.to output("---\nwarnings:\n  foo:\n  - i had a warning\n").to_stdout
    end
    it 'outputs files with no errors or warnings as yaml' do
      files = { clean: ['foo'] }
      expect { OutputResults.run(files, 'yaml') }.to output("---\nclean:\n- foo\n").to_stdout
    end
    it 'outputs files that were not processed as yaml' do
      files = { ignored: ['foo'] }
      expect { OutputResults.run(files, 'yaml') }.to output("---\nignored:\n- foo\n").to_stdout
    end
    it 'outputs files with errors as json' do
      files = { errors: { 'foo' => ['i had an error'] } }
      expect { OutputResults.run(files, 'json') }.to output("{\n  \"errors\": {\n    \"foo\": [\n      \"i had an error\"\n    ]\n  }\n}\n").to_stdout
    end
    it 'outputs files with warnings as json' do
      files = { warnings: { 'foo' => ['i had a warning'] } }
      expect { OutputResults.run(files, 'json') }.to output("{\n  \"warnings\": {\n    \"foo\": [\n      \"i had a warning\"\n    ]\n  }\n}\n").to_stdout
    end
    it 'outputs files with no errors or warnings as json' do
      files = { clean: ['foo'] }
      expect { OutputResults.run(files, 'json') }.to output("{\n  \"clean\": [\n    \"foo\"\n  ]\n}\n").to_stdout
    end
    it 'outputs files that were not processed as json' do
      files = { ignored: ['foo'] }
      expect { OutputResults.run(files, 'json') }.to output("{\n  \"ignored\": [\n    \"foo\"\n  ]\n}\n").to_stdout
    end
    it 'redirects to junit output formatting as expected' do
      expect { OutputResults.run({}, 'junit') }.to output("<?xml version='1.0' encoding='UTF-8'?><testsuite failures='0' name='puppet-check' skipped='0' tests='0'/>\n").to_stdout
    end
    it 'raises an error for an unsupported output format' do
      expect { OutputResults.run({}, 'awesomesauce') }.to raise_error(RuntimeError, 'puppet-check: Unsupported output format \'awesomesauce\' was specified.')
    end
  end
end