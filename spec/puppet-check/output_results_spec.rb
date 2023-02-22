require_relative '../spec_helper'
require_relative '../../lib/puppet-check/output_results'

describe OutputResults do
  before(:each) do
    PuppetCheck.files = {
      errors: {},
      warnings: {},
      clean: [],
      ignored: []
    }
  end

  context '.text' do
    it 'outputs files with errors' do
      PuppetCheck.files[:errors] = { 'foo' => ['i had an error'] }
      expect { OutputResults.text }.to output("\033[31mThe following files have errors:\033[0m\n-- foo:\ni had an error\n").to_stdout
    end
    it 'outputs files with warnings' do
      PuppetCheck.files[:warnings] = { 'foo' => ['i had a warning'] }
      expect { OutputResults.text }.to output("\n\033[33mThe following files have warnings:\033[0m\n-- foo:\ni had a warning\n").to_stdout
    end
    it 'outputs files with no errors or warnings' do
      PuppetCheck.files[:clean] = ['foo']
      expect { OutputResults.text }.to output("\n\033[32mThe following files have no errors or warnings:\033[0m\n-- foo\n").to_stdout
    end
    it 'outputs files that were not processed' do
      PuppetCheck.files[:ignored] = ['foo']
      expect { OutputResults.text }.to output("\n\033[36mThe following files have unrecognized formats and therefore were not processed:\033[0m\n-- foo\n").to_stdout
    end
  end

  context '.markup' do
    it 'outputs files with errors as yaml' do
      PuppetCheck.files[:errors] = { 'foo' => ['i had an error'] }
      expect { OutputResults.markup('yaml') }.to output("---\nerrors:\n  foo:\n  - i had an error\n").to_stdout
    end
    it 'outputs files with warnings as yaml' do
      PuppetCheck.files[:warnings] = { 'foo' => ['i had a warning'] }
      expect { OutputResults.markup('yaml') }.to output("---\nwarnings:\n  foo:\n  - i had a warning\n").to_stdout
    end
    it 'outputs files with no errors or warnings as yaml' do
      PuppetCheck.files[:clean] = ['foo']
      expect { OutputResults.markup('yaml') }.to output("---\nclean:\n- foo\n").to_stdout
    end
    it 'outputs files that were not processed as yaml' do
      PuppetCheck.files[:ignored] = ['foo']
      expect { OutputResults.markup('yaml') }.to output("---\nignored:\n- foo\n").to_stdout
    end
    it 'outputs files with errors as json' do
      PuppetCheck.files[:errors] = { 'foo' => ['i had an error'] }
      expect { OutputResults.markup('json') }.to output("{\n  \"errors\": {\n    \"foo\": [\n      \"i had an error\"\n    ]\n  }\n}\n").to_stdout
    end
    it 'outputs files with warnings as json' do
      PuppetCheck.files[:warnings] = { 'foo' => ['i had a warning'] }
      expect { OutputResults.markup('json') }.to output("{\n  \"warnings\": {\n    \"foo\": [\n      \"i had a warning\"\n    ]\n  }\n}\n").to_stdout
    end
    it 'outputs files with no errors or warnings as json' do
      PuppetCheck.files[:clean] = ['foo']
      expect { OutputResults.markup('json') }.to output("{\n  \"clean\": [\n    \"foo\"\n  ]\n}\n").to_stdout
    end
    it 'outputs files that were not processed as json' do
      PuppetCheck.files[:ignored] = ['foo']
      expect { OutputResults.markup('json') }.to output("{\n  \"ignored\": [\n    \"foo\"\n  ]\n}\n").to_stdout
    end
    it 'raises an error for an unsupported output format' do
      expect { OutputResults.markup('awesomesauce') }.to raise_error(RuntimeError, 'puppet-check: Unsupported output format \'awesomesauce\' was specified.')
    end
  end
end
