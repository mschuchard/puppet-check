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
      PuppetCheck.settings[:error_files].push("#{file}:\n#{err}")
    else
      # check ruby style
      if style
        require 'rubocop'

        # check RuboCop and collect warnings
        rubocop_warnings = Utils.capture_stdout { RuboCop::CLI.new.run(rc_args + ['--enable-pending-cops', '--require', 'rubocop-performance', '--format', 'emacs', file]) }
        warnings = rubocop_warnings == '' ? '' : rubocop_warnings.split("#{File.absolute_path(file)}:").join('')

        # check Reek and collect warnings
        require 'reek'
        require 'reek/cli/application'
        reek_warnings = Utils.capture_stdout { Reek::CLI::Application.new([file]).execute }
        warnings << reek_warnings.split("\n")[1..].map(&:strip).join("\n") unless reek_warnings == ''

        # return warnings
        next PuppetCheck.settings[:warning_files].push("#{file}:\n#{warnings.strip}") unless warnings == ''
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
                   # ERB.new(File.read(file), trim_mode: '-').result(RubyParser.new.bind)
      rescue NameError, TypeError
        # empty out warnings since it would contain an error if this pass triggers
        warnings = ''
      rescue ScriptError => err
        next PuppetCheck.settings[:error_files].push("#{file}:\n#{err}")
      end
      # return warnings from the check if there were any
      next PuppetCheck.settings[:warning_files].push("#{file}:\n#{warnings.gsub('warning: ', '').split('(erb):').join('').strip}") unless warnings == ''
      PuppetCheck.settings[:clean_files].push(file.to_s)
    end
  end

  # checks librarian puppet (Puppetfile/Modulefile) and misc ruby (Rakefile/Gemfile)
  def self.librarian(files, style, rc_args)
    # efficient var assignment prior to iterator
    if style
      require 'rubocop'

      # RuboCop is grumpy about non-snake_case filenames so disable the FileName check
      rc_args.include?('--except') ? rc_args[rc_args.index('--except') + 1] = "#{rc_args[rc_args.index('--except') + 1]},Naming/FileName" : rc_args.concat(['--except', 'Naming/FileName'])
    end

    files.each do |file|
      # check librarian puppet syntax
      # prevents ruby code from actually executing
      catch(:good) { instance_eval("BEGIN {throw :good}; #{File.read(file)}", file) }
    rescue SyntaxError, LoadError, ArgumentError => err
      PuppetCheck.settings[:error_files].push("#{file}:\n#{err}")
    # check librarian puppet style
    else
      if style
        # check Rubocop
        warnings = Utils.capture_stdout { RuboCop::CLI.new.run(rc_args + ['--enable-pending-cops', '--require', 'rubocop-performance', '--format', 'emacs', file]) }

        # collect style warnings
        next PuppetCheck.settings[:warning_files].push("#{file}:\n#{warnings.split("#{File.absolute_path(file)}:").join('')}") unless warnings.empty?
      end
      PuppetCheck.settings[:clean_files].push(file.to_s)
    end
  end

  # potentially for unique erb bindings
  def bind
    binding
  end
end
