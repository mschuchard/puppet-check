require 'optparse'
require_relative '../puppet-check'

# the command line interface for PuppetCheck
class PuppetCheck::CLI
  # run method for the cli
  def self.run(args)
    # gather the user arguments
    parse(args)
    raise 'puppet-check: no paths specified' if args.empty?

    # run PuppetCheck
    PuppetCheck.new.run(args)
  end

  # parse the user arguments
  def self.parse(args)
    opt_parser = OptionParser.new do |opts|
      # usage
      opts.banner = 'usage: puppet-check [options] paths'

      # base options
      opts.on('--version', 'Display the current version.') do
        puts 'puppet-check 1.3.2'
        exit 0
      end

      # bool options
      opts.on('-f', '--future', 'Enable future parser') { PuppetCheck.future_parser = true }
      opts.on('-s', '--style', 'Enable style checks') { PuppetCheck.style_check = true }

      # formatting options
      opts.on('-o', '--output format', String, 'Format for results output (default is text): text, json, or yaml') { |arg| PuppetCheck.output_format = arg }

      # arguments to style checkers
      opts.on('--puppet-lint arg_one,arg_two', Array, 'Arguments for PuppetLint ignored checks') do |puppetlint_args|
        PuppetCheck.puppetlint_args += puppetlint_args.map { |arg| "--#{arg}" }
      end
      opts.on('-c', '--config file', String, 'Load PuppetLint options from file.') do |file|
        PuppetCheck.puppetlint_args += File.read(file).split("\n")
      end
      opts.on('--rubocop arg_one,arg_two', String, 'Arguments for Rubocop disabled cops') { |arg| PuppetCheck.rubocop_args = ['--except', arg] }
    end

    opt_parser.parse!(args)
  end
end
