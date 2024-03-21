require_relative '../puppet_check'
require_relative 'utils'

# executes diagnostics on ruby files
class RubyParser
  # checks ruby (.rb)
  def self.ruby(files, style, rc_args)
    # prepare rubocop object for style checks
    if style
      require 'json'
      require 'rubocop'
      require 'reek'
      require 'reek/cli/application'

      rubocop_cli = RuboCop::CLI.new
    end

    files.each do |file|
      # check ruby syntax
      # prevents ruby code from actually executing
      catch(:good) { instance_eval("BEGIN {throw :good}; #{File.read(file)}", file) }
    rescue ScriptError, StandardError => err
      PuppetCheck.files[:errors][file] = err.to_s.gsub("#{file}:", '').split("\n")
    else
      # check ruby style
      if style
        # check RuboCop and parse warnings' JSON output
        rubocop_warnings = Utils.capture_stdout { rubocop_cli.run(rc_args + ['--enable-pending-cops', '--require', 'rubocop-performance', '--format', 'json', file]) }
        rubocop_offenses = JSON.parse(rubocop_warnings)['files'][0]['offenses'].map { |warning| "#{warning['location']['line']}:#{warning['location']['column']} #{warning['message']}" }

        # check Reek and parse warnings' JSON output
        reek_warnings = Utils.capture_stdout { Reek::CLI::Application.new(['-f', 'json', file]).execute }
        reek_offenses = JSON.parse(reek_warnings).map { |warning| "#{warning['lines'].join(',')}: #{warning['context']} #{warning['message']}" }

        # assign warnings from combined offenses
        warnings = rubocop_offenses + reek_offenses

        # return warnings
        next PuppetCheck.files[:warnings][file] = warnings unless warnings.empty?
      end
      PuppetCheck.files[:clean].push(file.to_s)
    end
  end

  # checks ruby template (.erb)
  def self.template(files)
    require 'erb'

    files.each do |file|
      # check ruby template syntax
      begin
        # need to eventually have this associated with a different binding during each iteration
        # older usage throws extra warning and mixes with valid warnings confusingly
        warnings = Utils.capture_stderr { ERB.new(File.read(file), trim_mode: '-').result }
        # warnings = ERB.new(File.read(file), trim_mode: '-').result(RubyParser.new.bind)
      rescue NameError, TypeError
        # empty out warnings since it would contain an error if this pass triggers
        warnings = ''
      rescue ScriptError => err
        next PuppetCheck.files[:errors][file] = err.to_s.gsub('(erb):', '').split("\n")
      end
      # return warnings from the check if there were any
      next PuppetCheck.files[:warnings][file] = warnings.to_s.gsub('warning: ', '').delete("\n").split('(erb):').compact unless warnings == ''
      PuppetCheck.files[:clean].push(file.to_s)
    end
  end

  # checks librarian puppet (Puppetfile/Modulefile) and misc ruby (Rakefile/Gemfile)
  def self.librarian(files, style, rc_args)
    # efficient var assignment prior to iterator
    if style
      require 'json'
      require 'rubocop'

      rubocop_cli = RuboCop::CLI.new

      # RuboCop is grumpy about non-snake_case filenames so disable the FileName check
      rc_args.include?('--except') ? rc_args[rc_args.index('--except') + 1] = "#{rc_args[rc_args.index('--except') + 1]},Naming/FileName" : rc_args.push('--except', 'Naming/FileName')
    end

    files.each do |file|
      # check librarian puppet syntax
      # prevents ruby code from actually executing
      catch(:good) { instance_eval("BEGIN {throw :good}; #{File.read(file)}", file) }
    rescue SyntaxError, LoadError, ArgumentError => err
      PuppetCheck.files[:errors][file] = err.to_s.gsub("#{file}:", '').split("\n")
    # check librarian puppet style
    else
      if style
        warnings = Utils.capture_stdout { rubocop_cli.run(rc_args + ['--enable-pending-cops', '--require', 'rubocop-performance', '--format', 'json', file]) }
        offenses = JSON.parse(warnings)['files'][0]['offenses'].map { |warning| "#{warning['location']['line']}:#{warning['location']['column']} #{warning['message']}" }

        # collect style warnings
        next PuppetCheck.files[:warnings][file] = offenses unless offenses.empty?
      end
      PuppetCheck.files[:clean].push(file.to_s)
    end
  end

  # potentially for unique erb bindings
  def bind
    binding
  end
end
