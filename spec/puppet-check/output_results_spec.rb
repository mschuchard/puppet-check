require_relative '../spec_helper'
require_relative '../../lib/puppet-check/output_results'

describe PuppetCheck do
  context '.output_results' do
    #
  end

  context '.text' do
    before(:each) do
      PuppetCheck.error_files = []
      PuppetCheck.warning_files = []
      PuppetCheck.clean_files = []
      PuppetCheck.ignored_files = []
    end

    it 'outputs files with errors' do
      PuppetCheck.error_files = ['foo: i had an error']
      expect { OutputResults.text }.to output("\033[31mThe following files have errors:\033[0m\n-- foo: i had an error\n").to_stdout
    end
    it 'outputs files with warnings' do
      PuppetCheck.warning_files = ['foo: i had a warning']
      expect { OutputResults.text }.to output("\n\033[33mThe following files have warnings:\033[0m\n-- foo: i had a warning\n").to_stdout
    end
    it 'outputs files with no errors or warnings' do
      PuppetCheck.clean_files = ['foo: i was totally good to go']
      expect { OutputResults.text }.to output("\n\033[32mThe following files have no errors or warnings:\033[0m\n-- foo: i was totally good to go\n").to_stdout
    end
    it 'outputs files that were not processed' do
      PuppetCheck.ignored_files = ['foo: who knows what i am']
      expect { OutputResults.text }.to output("\n\033[36mThe following files have unrecognized formats and therefore were not processed:\033[0m\n-- foo: who knows what i am\n").to_stdout
    end
  end

  context '.yaml' do
    before(:each) do
      PuppetCheck.error_files = []
      PuppetCheck.warning_files = []
      PuppetCheck.clean_files = []
      PuppetCheck.ignored_files = []
    end

    it 'outputs files with errors' do
      PuppetCheck.error_files = ['foo: i had an error']
      expect { OutputResults.yaml }.to output("---\nerrors:\n- 'foo: i had an error'\n").to_stdout
    end
    it 'outputs files with warnings' do
      PuppetCheck.warning_files = ['foo: i had a warning']
      expect { OutputResults.yaml }.to output("---\nwarnings:\n- 'foo: i had a warning'\n").to_stdout
    end
    it 'outputs files with no errors or warnings' do
      PuppetCheck.clean_files = ['foo: i was totally good to go']
      expect { OutputResults.yaml }.to output("---\nclean:\n- 'foo: i was totally good to go'\n").to_stdout
    end
    it 'outputs files that were not processed' do
      PuppetCheck.ignored_files = ['foo: who knows what i am']
      expect { OutputResults.yaml }.to output("---\nignored:\n- 'foo: who knows what i am'\n").to_stdout
    end
  end

  context '.json' do
    before(:each) do
      PuppetCheck.error_files = []
      PuppetCheck.warning_files = []
      PuppetCheck.clean_files = []
      PuppetCheck.ignored_files = []
    end

    it 'outputs files with errors' do
      PuppetCheck.error_files = ['foo: i had an error']
      expect { OutputResults.json }.to output("{\n  \"errors\": [\n    \"foo: i had an error\"\n  ]\n}\n").to_stdout
    end
    it 'outputs files with warnings' do
      PuppetCheck.warning_files = ['foo: i had a warning']
      expect { OutputResults.json }.to output("{\n  \"warnings\": [\n    \"foo: i had a warning\"\n  ]\n}\n").to_stdout
    end
    it 'outputs files with no errors or warnings' do
      PuppetCheck.clean_files = ['foo: i was totally good to go']
      expect { OutputResults.json }.to output("{\n  \"clean\": [\n    \"foo: i was totally good to go\"\n  ]\n}\n").to_stdout
    end
    it 'outputs files that were not processed' do
      PuppetCheck.ignored_files = ['foo: who knows what i am']
      expect { OutputResults.json }.to output("{\n  \"ignored\": [\n    \"foo: who knows what i am\"\n  ]\n}\n").to_stdout
    end
  end
end
