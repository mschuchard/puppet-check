require_relative '../spec_helper'
require_relative '../../lib/puppet-check/output_results'

describe OutputResults do
  context '.text' do
    before(:each) do
      PuppetCheck.settings[:error_files] = []
      PuppetCheck.settings[:warning_files] = []
      PuppetCheck.settings[:clean_files] = []
      PuppetCheck.settings[:ignored_files] = []
    end

    it 'outputs files with errors' do
      PuppetCheck.settings[:error_files] = ['foo: i had an error']
      expect { OutputResults.text }.to output("\033[31mThe following files have errors:\033[0m\n-- foo: i had an error\n").to_stdout
    end
    it 'outputs files with warnings' do
      PuppetCheck.settings[:warning_files] = ['foo: i had a warning']
      expect { OutputResults.text }.to output("\n\033[33mThe following files have warnings:\033[0m\n-- foo: i had a warning\n").to_stdout
    end
    it 'outputs files with no errors or warnings' do
      PuppetCheck.settings[:clean_files] = ['foo: i was totally good to go']
      expect { OutputResults.text }.to output("\n\033[32mThe following files have no errors or warnings:\033[0m\n-- foo: i was totally good to go\n").to_stdout
    end
    it 'outputs files that were not processed' do
      PuppetCheck.settings[:ignored_files] = ['foo: who knows what i am']
      expect { OutputResults.text }.to output("\n\033[36mThe following files have unrecognized formats and therefore were not processed:\033[0m\n-- foo: who knows what i am\n").to_stdout
    end
  end

  context '.markup' do
    before(:each) do
      PuppetCheck.settings[:error_files] = []
      PuppetCheck.settings[:warning_files] = []
      PuppetCheck.settings[:clean_files] = []
      PuppetCheck.settings[:ignored_files] = []
    end

    it 'outputs files with errors as yaml' do
      PuppetCheck.settings[:output_format] = 'yaml'
      PuppetCheck.settings[:error_files] = ['foo: i had an error']
      expect { OutputResults.markup }.to output("---\nerrors:\n- 'foo: i had an error'\n").to_stdout
    end
    it 'outputs files with warnings as yaml' do
      PuppetCheck.settings[:output_format] = 'yaml'
      PuppetCheck.settings[:warning_files] = ['foo: i had a warning']
      expect { OutputResults.markup }.to output("---\nwarnings:\n- 'foo: i had a warning'\n").to_stdout
    end
    it 'outputs files with no errors or warnings as yaml' do
      PuppetCheck.settings[:output_format] = 'yaml'
      PuppetCheck.settings[:clean_files] = ['foo: i was totally good to go']
      expect { OutputResults.markup }.to output("---\nclean:\n- 'foo: i was totally good to go'\n").to_stdout
    end
    it 'outputs files that were not processed as yaml' do
      PuppetCheck.settings[:output_format] = 'yaml'
      PuppetCheck.settings[:ignored_files] = ['foo: who knows what i am']
      expect { OutputResults.markup }.to output("---\nignored:\n- 'foo: who knows what i am'\n").to_stdout
    end
    it 'outputs files with errors as json' do
      PuppetCheck.settings[:output_format] = 'json'
      PuppetCheck.settings[:error_files] = ['foo: i had an error']
      expect { OutputResults.markup }.to output("{\n  \"errors\": [\n    \"foo: i had an error\"\n  ]\n}\n").to_stdout
    end
    it 'outputs files with warnings as json' do
      PuppetCheck.settings[:output_format] = 'json'
      PuppetCheck.settings[:warning_files] = ['foo: i had a warning']
      expect { OutputResults.markup }.to output("{\n  \"warnings\": [\n    \"foo: i had a warning\"\n  ]\n}\n").to_stdout
    end
    it 'outputs files with no errors or warnings as json' do
      PuppetCheck.settings[:output_format] = 'json'
      PuppetCheck.settings[:clean_files] = ['foo: i was totally good to go']
      expect { OutputResults.markup }.to output("{\n  \"clean\": [\n    \"foo: i was totally good to go\"\n  ]\n}\n").to_stdout
    end
    it 'outputs files that were not processed as json' do
      PuppetCheck.settings[:output_format] = 'json'
      PuppetCheck.settings[:ignored_files] = ['foo: who knows what i am']
      expect { OutputResults.markup }.to output("{\n  \"ignored\": [\n    \"foo: who knows what i am\"\n  ]\n}\n").to_stdout
    end
    it 'raises an error for an unsupported output format' do
      PuppetCheck.settings[:output_format] = 'awesomesauce'
      expect { OutputResults.markup }.to raise_error(RuntimeError, 'puppet-check: Unsupported output format \'awesomesauce\' was specified.')
    end
  end
end
