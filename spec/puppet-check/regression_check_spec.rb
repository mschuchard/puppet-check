require_relative '../spec_helper'
require_relative '../../lib/puppet-check/regression_check'

# once a good config is loaded, bad configs would have no effect so failures are tested first; config is also tested before compilation so that the good config can be loaded at the end and used for compilation and regression tests
describe RegressionCheck do
  context '.config' do
    it 'raise an appropriate error if the file is malformed' do
      expect { RegressionCheck.config(fixtures_dir + 'metadata.json') }.to raise_error(OctocatalogDiff::Errors::ConfigurationFileContentError, 'Configuration must define OctocatalogDiff::Config!')
    end
    it 'loads in a good octocatalog-diff config file' do
      expect { RegressionCheck.config(octocatalog_diff_dir + 'octocatalog-diff.cfg.rb') }.not_to raise_exception
    end
    it 'loads in the settings from the file correctly' do
      #
    end
  end

  context '.smoke' do
    # API requires :puppet_binary, which needs an absolute path, which is absurdly difficult to pull off for a matrix of travis ci rvm tests
    unless File.directory?('/home/travis')
      it 'returns a pass for a successful catalog compilation' do
        expect { RegressionCheck.smoke(['good.example.com'], "#{octocatalog_diff_dir}octocatalog-diff.cfg.rb") }.not_to raise_exception
      end
    end
    it 'returns a failure for a catalog with an error' do
      expect { RegressionCheck.smoke(['does_not_exist.example.com'], "#{octocatalog_diff_dir}octocatalog-diff.cfg.rb") }.to raise_error(OctocatalogDiff::Errors::CatalogError)
    end
    it 'returns a failure for a good and bad catalog' do
      # RegressionCheck.smoke(['good.example.com', 'syntax_error.example.com'], "#{fixtures_dir}octocatalog-diff.cfg.rb")
    end
  end

  context '.regression' do
    #
  end
end
