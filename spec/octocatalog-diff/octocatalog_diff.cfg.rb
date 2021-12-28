# This is a configuration file for octocatalog-diff (https://github.com/github/octocatalog-diff).
module OctocatalogDiff
  # Configuration class.
  class Config
    def self.config
      settings = {}
      octocatalog_diff_dir = "#{File.dirname(__FILE__)}/"

      settings[:hiera_config] = "#{octocatalog_diff_dir}hiera.yaml"
      settings[:hiera_path] = "#{octocatalog_diff_dir}hieradata"
      settings[:fact_file] = "#{octocatalog_diff_dir}facts.yaml"
      settings[:puppet_binary] = if File.directory?('/home/travis')
                                   "#{octocatalog_diff_dir}../../bin/puppet"
                                 else
                                   '/usr/local/bin/puppet'
                                 end
      settings[:bootstrapped_to_dir] = octocatalog_diff_dir

      settings
    end
  end
end
