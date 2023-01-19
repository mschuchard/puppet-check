require_relative '../puppet_check'
require_relative 'utils'

# executes diagnostics on ruby files
class RubyParser
  # checks ruby (.rb)
  def self.ruby(files, style, rc_args)
    files.each do |file|
      # check ruby syntax
      # prevents ruby code from actually executing
      catch(:good) { instance_eval("BEGIN {throw :good}; #{File.read(file)}", file) }
    rescue ScriptError, StandardError => err
      PuppetCheck.settings[:error_files][file] = err.to_s.gsub("#{file}:", '')
    else
      # check ruby style
      if style
        # check RuboCop and parse warnings JSON output
        require 'json'
        require 'rubocop'

        rubocop_warnings = Utils.capture_stdout { RuboCop::CLI.new.run(rc_args + ['--enable-pending-cops', '--require', 'rubocop-performance', '--format', 'json', file]) }
        rubocop_offenses = JSON.parse(rubocop_warnings)['files'][0]['offenses'].map { |warning| "#{warning['location']['line']}:#{warning['location']['column']} #{warning['message']}" }

        # check Reek
        require 'reek'
        require 'reek/cli/application'

        reek_warnings = Utils.capture_stdout { Reek::CLI::Application.new(['-f', 'json', file]).execute }
        reek_offenses = JSON.parse(reek_warnings).map { |warning| "#{warning['lines']}: #{warning['context']} #{warning['message']}" }

        # assign warnings from combined offenses
        warnings = rubocop_offenses + reek_offenses

        # return warnings
        next PuppetCheck.settings[:warning_files][file] = warnings unless warnings.empty?
      end
      PuppetCheck.settings[:clean_files].push(file.to_s)
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
        next PuppetCheck.settings[:error_files][file] = err.to_s.gsub('(erb):', '')
      end
      # return warnings from the check if there were any
      next PuppetCheck.settings[:warning_files][file] = warnings.to_s.gsub('warning: ', '').delete("\n").split('(erb):').compact unless warnings == ''
      PuppetCheck.settings[:clean_files].push(file.to_s)
    end
  end

  # checks librarian puppet (Puppetfile/Modulefile) and misc ruby (Rakefile/Gemfile)
  def self.librarian(files, style, rc_args)
    # efficient var assignment prior to iterator
    if style
      # RuboCop is grumpy about non-snake_case filenames so disable the FileName check
      rc_args.include?('--except') ? rc_args[rc_args.index('--except') + 1] = "#{rc_args[rc_args.index('--except') + 1]},Naming/FileName" : rc_args.push('--except', 'Naming/FileName')
    end

    files.each do |file|
      # check librarian puppet syntax
      # prevents ruby code from actually executing
      catch(:good) { instance_eval("BEGIN {throw :good}; #{File.read(file)}", file) }
    rescue SyntaxError, LoadError, ArgumentError => err
      PuppetCheck.settings[:error_files][file] = err.to_s.gsub("#{file}:", '')
    # check librarian puppet style
    else
      if style
        # check Rubocop
        require 'json'
        require 'rubocop'

        warnings = Utils.capture_stdout { RuboCop::CLI.new.run(rc_args + ['--enable-pending-cops', '--require', 'rubocop-performance', '--format', 'json', file]) }
        offenses = JSON.parse(warnings)['files'][0]['offenses'].map { |warning| "#{warning['location']['line']}:#{warning['location']['column']} #{warning['message']}" }

        # collect style warnings
        next PuppetCheck.settings[:warning_files][file] = offenses unless offenses.empty?
      end
      PuppetCheck.settings[:clean_files].push(file.to_s)
    end
  end

  # potentially for unique erb bindings
  def bind
    binding
  end
end
