require 'puppet'
require_relative '../puppet-check'

# executes diagnostics on puppet files
class PuppetParser
  # checks puppet (.pp)
  def self.manifest(files, future, style, pl_args)
    require 'puppet/face'

    # prepare the Puppet settings for the error checking
    Puppet.initialize_settings unless Puppet.settings.app_defaults_initialized?
    Puppet[:parser] = 'future' if future && (Puppet::PUPPETVERSION.to_i < 4)

    files.each do |file|
      # setup error logging and collection
      errors = []
      Puppet::Util::Log.newdestination(Puppet::Test::LogCollector.new(errors))

      # check puppet syntax
      begin
        Puppet::Face[:parser, :current].validate(file)
      # this is the actual error that we need to rescue Puppet::Face from
      rescue SystemExit
        # puppet 5 can only do one error per line and outputs fake dir env info
        next PuppetCheck.settings[:error_files].push("#{file}:\n#{errors.map(&:to_s).join("\n").gsub("#{File.absolute_path(file)}:", '').gsub(/Could not parse.*: /, '')}") if Puppet::PUPPETVERSION.to_i == 5
        # puppet < 5 parser output style
        next PuppetCheck.settings[:error_files].push("#{file}:\n#{errors.map(&:to_s).join("\n").gsub("#{File.absolute_path(file)}:", '')}")
      end

      # initialize warnings with output from the parser if it exists, since the output is warnings if Puppet::Face did not trigger a SystemExit
      warnings = errors.empty? ? "#{file}:" : "#{file}:\n#{errors.map(&:to_s).join("\n").gsub("#{File.absolute_path(file)}:", '')}"
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
      PuppetCheck.settings[:clean_files].push(file.to_s)
    end
  end

  # checks puppet template (.epp)
  def self.template(files)
    require 'puppet/pops'

    files.each do |file|
      # puppet before version 4 cannot check template syntax
      next PuppetCheck.settings[:ignored_files].push("#{file}: ignored due to Puppet < 4") if Puppet::PUPPETVERSION.to_i < 4

      # check puppet template syntax
      begin
        # credits to gds-operations/puppet-syntax for the parser function call
        Puppet::Pops::Parser::EvaluatingParser::EvaluatingEppParser.new.parse_file(file)
      rescue StandardError => err
        PuppetCheck.settings[:error_files].push("#{file}:\n#{err.to_s.gsub("#{file}:", '')}")
      else
        PuppetCheck.settings[:clean_files].push(file.to_s)
      end
    end
  end
end
