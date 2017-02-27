require_relative '../spec_helper'
require_relative '../../lib/puppet-check/regression_check'

describe RegressionCheck do
  context '.compile' do
    it 'returns a pass for a successful catalog compilation' do
      # RegressionCheck.compile(['good.example.com'])
    end
    it 'returns a failure for a catalog with a syntax error' do
      # RegressionCheck.compile(['syntax_error.example.com'])
    end
    it 'returns a failure for a good and bad catalog' do
      # RegressionCheck.compile(['good.example.com', 'syntax_error.example.com'])
    end
  end

  context '.regression' do
    #
  end

  context '.config' do
    it 'loads in a good octocatalog-diff config file' do
      expect { RegressionCheck.config(fixtures_dir + 'octocatalog-diff.cfg.rb') }.not_to raise_exception
    end
    it 'raises an appropriate error if the file was not found and test mode is true' do
      # TODO: needs test: true
    end
    it 'raise an appropriate error if the file is malformed' do
      # TODO: wait on response from kevin
      #expect { RegressionCheck.config('/home/matt/git_repos/puppet-check/spec/fixtures/metadata.json') }.to raise_error(OctocatalogDiff::Errors::ConfigurationFileContentError, 'Configuration must define OctocatalogDiff::Config!')
    end
    it 'loads in the settings from the file correctly' do
      #
    end
  end
end
