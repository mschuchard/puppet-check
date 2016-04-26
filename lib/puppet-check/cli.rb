require 'optparse'
require_relative '../puppet-check'

# the command line interface for PuppetCheck
class PuppetCheck::CLI
  # run method for the cli
  def self.run(args)
    parse(args)
    raise 'puppet-check: no paths specified' if args.empty?

    # run PuppetCheck
    PuppetCheck.new.run(args)
    0
  end

  # parse the user arguments
  def self.parse(args)
    opt_parser = OptionParser.new do |opts|
      # usage
      opts.banner = 'usage: puppet-check [options] paths'

      # bool options
      opts.on('-f', '--future', 'Enable future parser') { PuppetCheck.future_parser = true }
      opts.on('-s', '--style', 'Enable style checks') { PuppetCheck.style_check = true }
      # arguments to style checkers
      opts.on('--puppet-lint arg_one,arg_two', Array, 'Arguments for PuppetLint ignored checks') do |puppetlint_args|
        PuppetCheck.puppetlint_args = puppetlint_args.map { |arg| "--#{arg}" }
      end
      opts.on('--rubocop arg_one,arg_two', String, 'Arguments for Rubocop disabled cops') { |arg| PuppetCheck.rubocop_args = ['--except', arg] }
    end

    opt_parser.parse!(args)
  end
end
