require 'puppet'
require_relative '../puppet_check'

# executes diagnostics on puppet files
class PuppetParser
  # checks puppet (.pp)
  def self.manifest(files, style, pl_args)
    require 'puppet/face'

    # prepare the Puppet settings for the error checking
    Puppet.initialize_settings unless Puppet.settings.app_defaults_initialized?

    files.each do |file|
      # setup error logging and collection; warnings logged for all versions, but errors for only puppet < 6.5
      errors = []
      Puppet::Util::Log.newdestination(Puppet::Test::LogCollector.new(errors))

      # check puppet syntax
      begin
        # initialize message
        message = ''
        # specify tasks attribute for parser validation if this looks like a plan or not
        Puppet[:tasks] = file.match?(%r{plans/\w+\.pp$})
        # in puppet >= 6.5 the return of this method is a hash with the error
        new_error = Puppet::Face[:parser, :current].validate(file)
        # puppet 6.5 output format is now a hash from the face api
        if Gem::Version.new(Puppet::PUPPETVERSION) >= Gem::Version.new('6.5.0') && new_error != {}
          message = new_error.values.map(&:to_s).join("\n").gsub(/ \(file: #{File.absolute_path(file)}(, |\))/, '').gsub('Could not parse for environment *root*: ', '')
        end
      # this is the actual error that we need to rescue Puppet::Face from
      rescue SystemExit
        # puppet 5.4-6.4 has a new validator output format and eof errors have fake dir env info
        message = errors.map(&:to_s).join("\n").gsub(/file: #{File.absolute_path(file)}(, |\))/, '').gsub(/Could not parse.*: /, '')
      end
      # output message
      next PuppetCheck.settings[:error_files].push("#{file}:\n#{message}") unless message.empty?

      # initialize warnings with output from the parser if it exists, since the output is warnings if Puppet::Face did not trigger a SystemExit
      warnings = "#{file}:"
      unless errors.empty?
        # puppet >= 5.4 has a new validator output format
        warnings << "\n#{errors.map(&:to_s).join("\n").gsub("file: #{File.absolute_path(file)}, ", '')}"
      end
      Puppet::Util::Log.close_all

      # check puppet style
      if style
        require 'puppet-lint'
        require 'puppet-lint/optparser'

        # check for invalid arguments to PuppetLint
        begin
          PuppetLint::OptParser.build.parse!(pl_args.clone)
        rescue OptionParser::InvalidOption
          raise "puppet-lint: invalid option supplied among #{pl_args.join(' ')}"
        end

        # prepare the PuppetLint object for style checks
        puppet_lint = PuppetLint.new
        puppet_lint.file = file
        puppet_lint.run

        # collect the warnings
        if puppet_lint.warnings?
          puppet_lint.problems.each { |values| warnings << "\n#{values[:line]}:#{values[:column]}: #{values[:message]}" }
        end
      end
      next PuppetCheck.settings[:warning_files].push(warnings) unless warnings == "#{file}:"
      PuppetCheck.settings[:clean_files][file] = nil
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
      PuppetCheck.settings[:error_files].push("#{file}:\n#{err.to_s.gsub("#{file}:", '')}")
    else
      PuppetCheck.settings[:clean_files][file] = nil
    end
  end
end
