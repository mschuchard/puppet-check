require 'optparse'
require_relative '../puppet-check'

# the command line interface for PuppetCheck
class PuppetCheck::CLI
  # run method for the cli
  def self.run(args)
    # gather the user arguments
    parse(args)
    raise 'puppet-check: no paths specified; try using --help' if args.empty?

    # run PuppetCheck with specified paths
    PuppetCheck.new.run(args)
  end

  # parse the user arguments
  def self.parse(args)
    # show help message if no args specified
    args = %w[-h] if args.empty?

    # initialize settings hash
    settings = {}

    # initialize future parser, fail on warning,  style check, and regression check bools
    settings[:future_parser] = false
    settings[:fail_on_warning] = false
    settings[:style_check] = false
    settings[:smoke_check] = false
    settings[:regression_check] = false

    # initialize ssl keys for eyaml checks
    settings[:public] = nil
    settings[:private] = nil

    # initialize output format option
    settings[:output_format] = 'text'

    # initialize octocatalog-diff options
    settings[:octoconfig] = '.octocatalog-diff.cfg.rb'
    settings[:octonodes] = %w[localhost.localdomain]

    # initialize diagnostic output arrays
    settings[:error_files] = []
    settings[:warning_files] = []
    settings[:clean_files] = []
    settings[:ignored_files] = []

    # initialize style arg arrays
    settings[:puppetlint_args] = []
    settings[:rubocop_args] = []

    opt_parser = OptionParser.new do |opts|
      # usage
      opts.banner = 'usage: puppet-check [options] paths'

      # base options
      opts.on('--version', 'Display the current version.') do
        puts 'puppet-check 1.5.1'
        exit 0
      end

      # bool options
      opts.on('-f', '--future', 'Enable future parser') { settings[:future_parser] = true }
      opts.on('--fail-on-warnings', 'Fail on warnings') { settings[:fail_on_warnings] = true }
      opts.on('-s', '--style', 'Enable style checks') { settings[:style_check] = true }
      opts.on('--smoke', 'Enable smoke testing') { settings[:smoke_check] = true }
      opts.on('-r', '--regression', 'Enable regression testing (in progress, do not use)') { settings[:regression_check] = true }

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
        settings[:puppetlint_args].concat(puppetlint_args.map { |arg| "--#{arg}" })
      end
      opts.on('-c', '--config file', String, 'Load PuppetLint options from file') do |file|
        settings[:puppetlint_args].concat(File.read(file).split("\n"))
      end
      opts.on('--rubocop arg_one,arg_two', String, 'Arguments for Rubocop disabled cops') { |arg| settings[:rubocop_args] = ['--except', arg] }
    end

    PuppetCheck.settings = settings
    opt_parser.parse!(args)
  end
end
