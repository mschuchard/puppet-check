# This is a configuration file for octocatalog-diff (https://github.com/github/octocatalog-diff).
module OctocatalogDiff
  # Configuration class.
  class Config
    def self.config
      settings = {}
      fixtures_dir = File.dirname(__FILE__) + '/'

      settings[:hiera_config] = fixtures_dir + 'hiera.yaml'
      settings[:hiera_path] = fixtures_dir + 'hieradata'
      settings[:fact_file] = fixtures_dir + 'hieradata/good.yaml'
      settings[:puppet_binary] = '/usr/local/bin/puppet'
      settings[:bootstrapped_to_dir] = fixtures_dir

      settings
    end
  end
end
