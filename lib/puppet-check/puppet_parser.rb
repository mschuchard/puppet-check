require 'puppet'
require_relative '../puppet-check'

# executes diagnostics on puppet files
class PuppetParser
  # checks puppet syntax and style (.pp)
  def self.manifest(file)
    require 'puppet/face'
    # we need this for 'reasons'
    Puppet.initialize_settings unless Puppet.settings.app_defaults_initialized?
    Puppet[:parser] = 'future' if PuppetCheck.future_parser && (Puppet::PUPPETVERSION.to_i < 4)
    # check puppet syntax
    errors = []
    Puppet::Util::Log.newdestination(Puppet::Test::LogCollector.new(errors))
    begin
      Puppet::Face[:parser, :current].validate(file)
    # this is the error that we need to rescue Puppet::Face from
    rescue SystemExit
      return PuppetCheck.error_files.push("-- #{file}: #{errors.map(&:to_s).join("\n").gsub("#{file}:", '')}")
      # TODO: RC rescue warnings and dump in style array
    end
    Puppet::Util::Log.close_all
    # check puppet style
    if PuppetCheck.style_check
      require 'puppet-lint'
      require 'puppet-lint/optparser'
      # check for invalid arguments to PuppetLint
      begin
        PuppetLint::OptParser.build.parse!(PuppetCheck.puppetlint_args)
      rescue OptionParser::InvalidOption
        raise 'puppet-lint: invalid option'
      end
      # check the style
      puppet_lint = PuppetLint.new
      puppet_lint.file = file
      puppet_lint.run
      # catalog the warnings
      if puppet_lint.warnings?
        warning = "-- #{file}: "
        puppet_lint.problems.each { |values| warning += "#{values[:message]} at line #{values[:line]}, column #{values[:column]}\n" }
        return PuppetCheck.warning_files.push(warning)
      end
    end
    PuppetCheck.clean_files.push("-- #{file}")
  end

  # checks puppet teplate syntax (.epp)
  def self.template(file)
    require 'puppet/pops'
    # puppet before version 4 cannot check template syntax
    return PuppetCheck.ignored_files.push("-- #{file}: ignored due to Puppet Agent < 4.0.0") if Puppet::PUPPETVERSION.to_i < 4

    # check puppet template syntax
    begin
      # credits to gds-operations/puppet-syntax for the parser function call
      Puppet::Pops::Parser::EvaluatingParser::EvaluatingEppParser.new.parse_file(file)
    rescue StandardError => err
      PuppetCheck.error_files.push("-- #{file}: #{err.to_s.gsub("#{file}:", '')}")
      # TODO: RC rescue warnings and dump in style array
    else
      PuppetCheck.clean_files.push("-- #{file}")
    end
  end
end
