require_relative '../puppet-check'
require_relative 'utils'

# executes diagnostics on ruby files
class RubyParser
  # checks ruby (.rb)
  def self.ruby(files)
    files.each do |file|
      # check ruby syntax
      begin
        catch(:good) { instance_eval("BEGIN {throw :good}; #{File.read(file)}") }
      rescue ScriptError, StandardError => err
        PuppetCheck.error_files.push("-- #{file}:\n#{err}")
      else
        # check ruby style
        if PuppetCheck.style_check
          require 'rubocop'

          # check RuboCop and collect warnings
          rubocop_warnings = Utils.capture_stdout { RuboCop::CLI.new.run(PuppetCheck.rubocop_args + ['--format', 'emacs', file]) }
          warnings = rubocop_warnings == '' ? '' : rubocop_warnings.split("#{File.absolute_path(file)}:").join('')

          # check Reek
          if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.1.0')
            require 'reek'
            require 'reek/cli/application'
            reek_warnings = Utils.capture_stdout { Reek::CLI::Application.new([file]).execute }
            warnings += reek_warnings.split("\n")[1..-1].map(&:strip).join("\n") unless reek_warnings == ''
          end

          # return warnings
          next PuppetCheck.warning_files.push("-- #{file}:\n#{warnings.strip}") unless warnings == ''
        end
        PuppetCheck.clean_files.push("-- #{file}")
      end
    end
  end

  # checks ruby template (.erb)
  def self.template(files)
    require 'erb'

    files.each do |file|
      # check ruby template syntax
      begin
        # need to eventually have this associated with a different binding during each iteration
        # warnings = Util.capture_stderr { ERB.new(File.read(file), nil, '-').result(RubyParser.new.binding) }
        warnings = Utils.capture_stderr { ERB.new(File.read(file), nil, '-').result }
      # credits to gds-operations/puppet-syntax for errors to ignore
      rescue NameError, TypeError
        # empty out warnings since it would contain an error if this pass triggers
        warnings = ''
      rescue ScriptError => err
        next PuppetCheck.error_files.push("-- #{file}:\n#{err}")
      end
      # return warnings from the check if there were any
      next PuppetCheck.warning_files.push("-- #{file}:\n#{warnings.gsub('warning: ', '').split('(erb):').join('').strip}") unless warnings == ''
      PuppetCheck.clean_files.push("-- #{file}")
    end
  end

  # checks librarian puppet (Puppetfile/Modulefile) and misc ruby (Rakefile/Gemfile)
  def self.librarian(files)
    files.each do |file|
      begin
        # check librarian puppet syntax
        catch(:good) { instance_eval("BEGIN {throw :good}; #{File.read(file)}") }
      rescue SyntaxError, LoadError, ArgumentError => err
        PuppetCheck.error_files.push("-- #{file}:\n#{err}")
      else
        # check librarian puppet style
        if PuppetCheck.style_check
          require 'rubocop'

          # check Rubocop
          rubocop_args = PuppetCheck.rubocop_args.clone
          # RuboCop is confused about the first 'mod' argument in librarian puppet (and Rakefiles and Gemfiles) so disable the Style/FileName check
          rubocop_args.include?('--except') ? rubocop_args[rubocop_args.index('--except') + 1] = "#{rubocop_args[rubocop_args.index('--except') + 1]},Style/FileName" : rubocop_args.concat(['--except', 'Style/FileName'])
          warnings = Utils.capture_stdout { RuboCop::CLI.new.run(rubocop_args + ['--format', 'emacs', file]) }

          # collect style warnings
          next PuppetCheck.warning_files.push("-- #{file}:\n#{warnings.split("#{File.absolute_path(file)}:").join('')}") unless warnings.empty?
        end
        PuppetCheck.clean_files.push("-- #{file}")
      end
    end
  end

  # potentially for unique erb bindings
  def binding
    binding
  end
end
