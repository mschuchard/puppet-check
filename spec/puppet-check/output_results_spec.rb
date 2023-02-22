require_relative '../spec_helper'
require_relative '../../lib/puppet-check/output_results'

describe OutputResults do
  context '.text' do
    it 'outputs files with errors' do
      files = { errors: { 'foo' => ['i had an error'] } }
      expect { OutputResults.text(files) }.to output("\033[31mThe following files have errors:\033[0m\n-- foo:\ni had an error\n").to_stdout
    end
    it 'outputs files with warnings' do
      files = { warnings: { 'foo' => ['i had a warning'] } }
      expect { OutputResults.text(files) }.to output("\n\033[33mThe following files have warnings:\033[0m\n-- foo:\ni had a warning\n").to_stdout
    end
    it 'outputs files with no errors or warnings' do
      files = { clean: ['foo'] }
      expect { OutputResults.text(files) }.to output("\n\033[32mThe following files have no errors or warnings:\033[0m\n-- foo\n").to_stdout
    end
    it 'outputs files that were not processed' do
      files = { ignored: ['foo'] }
      expect { OutputResults.text(files) }.to output("\n\033[36mThe following files have unrecognized formats and therefore were not processed:\033[0m\n-- foo\n").to_stdout
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
    it 'raises an error for an unsupported output format' do
      expect { OutputResults.run({}, 'awesomesauce') }.to raise_error(RuntimeError, 'puppet-check: Unsupported output format \'awesomesauce\' was specified.')
    end
  end
end
