require 'optparse'
require_relative '../puppet_check'

# the command line interface for PuppetCheck
class PuppetCheck::CLI
  # run method for the cli
  def self.run(args)
    # gather the user arguments
    settings = parse(args)
    raise 'puppet-check: no paths specified; try using --help' if args.empty?

    # run PuppetCheck with specified paths
    PuppetCheck.new.run(settings, args)
  end

  # parse the user arguments
  def self.parse(args)
    private_class_method :method
    # show help message if no args specified
    args = %w[-h] if args.empty?

    # initialize settings hash
    settings = {}

    opt_parser = OptionParser.new do |opts|
      # usage
      opts.banner = 'usage: puppet-check [options] paths'

      # base options
      opts.on('--version', 'Display the current version.') do
        puts 'puppet-check 2.2.0'
        exit 0
      end

      # bool options
      opts.on('--fail-on-warnings', 'Fail on warnings') { settings[:fail_on_warnings] = true }
      opts.on('-s', '--style', 'Enable style checks') { settings[:style] = true }
      opts.on('--smoke', 'Enable smoke testing') { settings[:smoke] = true }
      opts.on('-r', '--regression', 'Enable regression testing (in progress, do not use)') { settings[:regression] = true }

      # ssl key options for eyaml checks
      opts.on('--public cert.pem', String, 'Public key for EYAML checks') { |arg| settings[:public] = arg }
      opts.on('--private cert.pem', String, 'Private key for EYAML checks') { |arg| settings[:private] = arg }

      # formatting options
      opts.on('-o', '--output format', String, 'Format for results output (default is text): text, json, or yaml') { |arg| settings[:output_format] = arg }

      # octocatalog-diff options
      opts.on('--octoconfig config_file', String, 'Octocatalog-diff configuration file to use') { |arg| settings[:octoconfig] = arg }
      opts.on('-n', '--octonodes node1.example.com,node2.example.com', Array, 'Octocatalog-diff nodes to test catalog on') { |arg| settings[:octonodes] = arg }

      # arguments to style checkers
      opts.on('--puppet-lint arg_one,arg_two', Array, 'Arguments for PuppetLint ignored checks') do |puppetlint_args|
        settings[:puppetlint_args] = puppetlint_args.map { |arg| "--#{arg}" }
      end
      opts.on('-c', '--config file', String, 'Load PuppetLint options from file') do |file|
        settings[:puppetlint_args] = File.read(file).split("\n")
      end
      opts.on('--rubocop arg_one,arg_two', String, 'Arguments for Rubocop disabled cops') { |arg| settings[:rubocop_args] = ['--except', arg] }
    end

    # remove atched args and return settings
    opt_parser.parse!(args)
    settings
  end
end
