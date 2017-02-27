# This is a configuration file for octocatalog-diff (https://github.com/github/octocatalog-diff).
module OctocatalogDiff
  # Configuration class.
  class Config
    def self.config
      settings = {}

      settings[:hiera_config] = 'hiera.yaml'
      settings[:hiera_path] = 'hieradata'

      # settings[:puppetdb_url] = 'https://puppetdb.yourcompany.com:8081'
      # settings[:puppetdb_ssl_ca] = '/etc/puppetlabs/puppet/ssl/certs/ca.pem'

      # require 'socket'
      # fqdn = Socket.gethostbyname(Socket.gethostname).first
      # settings[:puppetdb_ssl_client_key] = File.read("/etc/puppetlabs/puppet/ssl/private_keys/#{fqdn}.pem")
      # settings[:puppetdb_ssl_client_cert] = File.read("/etc/puppetlabs/puppet/ssl/certs/#{fqdn}.pem")
      # settings[:puppetdb_ssl_client_password] = 'your-password-here'

      # settings[:enc] = '/etc/puppetlabs/puppet/enc.sh' # Absolute path
      # settings[:enc] = 'environments/production/config/enc.sh' # Relative path

      settings[:storeconfigs] = false

      # settings[:bootstrap_script] = '/etc/puppetlabs/repo-bootstrap.sh' # Absolute path
      # settings[:bootstrap_script] = 'script/bootstrap' # Relative path

      # settings[:pass_env_vars] = %w(AUTH_USERNAME AUTH_TOKEN)

      settings[:puppet_binary] = '/usr/local/bin/puppet'

      settings[:from_env] = 'origin/master'
      settings[:validate_references] = %w(before notify require subscribe)
      settings[:header] = :default
      settings[:cached_master_dir] = File.join(ENV['HOME'], '.octocatalog-diff-cache')
      settings[:safe_to_delete_cached_master_dir] = settings[:cached_master_dir]
      settings[:basedir] = Dir.pwd
      settings
    end
  end
end
