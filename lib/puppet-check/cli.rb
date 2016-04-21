# TODO: RC verbose logging eventually
# TODO: B add ARG parser method that assigns user options

require 'optparse'
require_relative '../puppet-check'

# the command line interface for PuppetCheck
class PuppetCheck::CLI
  def self.run(args)
    parse(args)

    raise 'puppet-check: no paths specified' if args.empty?
    PuppetCheck.new.run(args)
    0
  end

  def self.parse(args)
    opt_parser = OptionParser.new do |opts|
      opts.banner = 'usage: puppet-check [options] paths'

      opts.on('-f', '--future', 'Enable future parser') { PuppetCheck.future_parser = true }
      opts.on('-s', '--style', 'Enable style checks') { PuppetCheck.style_check = true }
      opts.on('--puppet-lint', 'Arguments/Options to pass to PuppetLint') {}
      opts.on('--rubocop', 'Arguments/Options to pass to Rubocop') {}
      opts.on('--reek', 'Arguments/Options to pass to Reek') {}
    end

    opt_parser.parse!(args)
  end
end
