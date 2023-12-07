require 'puppet'
require_relative '../puppet_check'

# executes diagnostics on puppet files
class PuppetParser
  # checks puppet (.pp)
  def self.manifest(files, style, pl_args)
    require 'puppet/face'

    # prepare the Puppet settings for the error checking
    Puppet.initialize_settings unless Puppet.settings.app_defaults_initialized?

    # prepare the PuppetLint object for style checks
    if style
      require 'puppet-lint'
      require 'puppet-lint/optparser'
      puppet_lint = PuppetLint.new
    end

    files.each do |file|
      # setup error logging and collection; warnings logged for all versions, but errors for only puppet < 6.5
      errors = []
      Puppet::Util::Log.newdestination(Puppet::Test::LogCollector.new(errors))

      # check puppet syntax
      begin
        # initialize message
        messages = []
        # specify tasks attribute for parser validation if this looks like a plan or not
        Puppet[:tasks] = file.match?(%r{plans/\w+\.pp$})
        # in puppet >= 6.5 the return of this method is a hash with the error
        new_error = Puppet::Face[:parser, :current].validate(file)
        # puppet 6.5 output format is now a hash from the face api
        if Gem::Version.new(Puppet::PUPPETVERSION) >= Gem::Version.new('6.5.0') && new_error != {}
          messages.concat(new_error.values.map(&:to_s).map { |error| error.gsub(/ \(file: #{File.absolute_path(file)}(, |\))/, '') }.map { |error| error.gsub('Could not parse for environment *root*: ', '') })
        end
      # this is the actual error that we need to rescue Puppet::Face from
      rescue SystemExit
        # puppet 5.4-6.4 has a new validator output format and eof errors have fake dir env info
        messages.concat(errors.map(&:to_s).join("\n").map { |error| error.gsub(/file: #{File.absolute_path(file)}(, |\))/, '') }.map { |error| error.gsub(/Could not parse.*: /, '') })
      end

      Puppet::Util::Log.close_all

      # store info and continue validating files
      next PuppetCheck.files[:errors][file] = messages unless messages.empty?

      # initialize warnings with output from the parser if it exists, since the output is warnings if Puppet::Face did not trigger a SystemExit
      warnings = []
      # weirdly puppet >= 6.5 still does not return warnings and logs them instead unlike errors
      unless errors.empty?
        # puppet >= 5.4 has a new validator output format
        warnings.concat(errors.map(&:to_s).join("\n").gsub("file: #{File.absolute_path(file)}, ", '').split("\n"))
      end

      # check puppet style
      if style
        # check for invalid arguments to PuppetLint
        begin
          PuppetLint::OptParser.build.parse!(pl_args.clone)
        rescue OptionParser::InvalidOption
          raise "puppet-lint: invalid option supplied among #{pl_args.join(' ')}"
        end

        # execute puppet-lint style checks
        puppet_lint.file = file
        puppet_lint.run

        # collect the warnings
        offenses = puppet_lint.problems.map { |problem| "#{problem[:line]}:#{problem[:column]} #{problem[:message]}" }
        warnings.concat(offenses)
      end
      next PuppetCheck.files[:warnings][file] = warnings unless warnings.empty?
      PuppetCheck.files[:clean].push(file.to_s)
    end
  end

  # checks puppet template (.epp)
  def self.template(files)
    require 'puppet/pops'

    files.each do |file|
      # check puppet template syntax
      # credits to gds-operations/puppet-syntax for the parser function call
      Puppet::Pops::Parser::EvaluatingParser::EvaluatingEppParser.new.parse_file(file)
    rescue StandardError => err
      PuppetCheck.files[:errors][file] = [err.to_s.gsub("file: #{file}, ", '')]
    else
      PuppetCheck.files[:clean].push(file.to_s)
    end
  end
end
