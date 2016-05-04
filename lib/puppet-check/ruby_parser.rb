require_relative '../puppet-check'

# executes diagnostics on ruby files
class RubyParser
  # checks ruby syntax and style (.rb)
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

          # check RuboCop and catalog warnings
          rubocop_warnings = capture_stdout { RuboCop::CLI.new.run(PuppetCheck.rubocop_args + ['--format', 'emacs', file]) }
          warnings = rubocop_warnings == '' ? '' : rubocop_warnings.split("#{File.absolute_path(file)}:").join('')

          # check Reek
          if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.1.0')
            require 'reek'
            require 'reek/cli/application'
            reek_warnings = capture_stdout { Reek::CLI::Application.new([file]).execute }
            warnings += reek_warnings.split("\n")[1..-1].join('').strip unless reek_warnings == ''
          end

          # return warnings
          next PuppetCheck.warning_files.push("-- #{file}:\n#{warnings.strip}") unless warnings == ''
        end
        PuppetCheck.clean_files.push("-- #{file}")
      end
    end
  end

  # checks ruby template syntax (.erb)
  def self.template(files)
    require 'erb'

    files.each do |file|
      # check ruby template syntax
      begin
        # TODO: RC erb is loading each template onto the old here it seems
        warnings = capture_stderr { ERB.new(File.read(file), nil, '-').result }
      # credits to gds-operations/puppet-syntax for errors to ignore
      rescue NameError, TypeError
      rescue ScriptError => err
        next PuppetCheck.error_files.push("-- #{file}:\n#{err}")
      end
      # return warnings from the check if there were any
      next PuppetCheck.warning_files.push("-- #{file}:\n#{warnings.gsub('warning: ', '').split('(erb):').join('').strip}") unless warnings == ''
      PuppetCheck.clean_files.push("-- #{file}")
    end
  end

  # checks librarian puppet syntax (Puppetfile/Modulefile)
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
          # RuboCop is confused about the first 'mod' argument in librarian puppet so disable the Style/FileName check
          rubocop_args.include?('--except') ? rubocop_args[rubocop_args.index('--except') + 1] = "#{rubocop_args[rubocop_args.index('--except') + 1]},Style/FileName" : rubocop_args.concat(['--except', 'Style/FileName'])
          warnings = capture_stdout { RuboCop::CLI.new.run(rubocop_args + ['--format', 'emacs', file]) }

          # catalog style warnings
          next PuppetCheck.warning_files.push("-- #{file}:\n#{warnings.split("#{File.absolute_path(file)}:").join('')}") unless warnings.empty?
        end
        PuppetCheck.clean_files.push("-- #{file}")
      end
    end
  end
end

# utility function to capture stdout
def capture_stdout
  old_stdout = $stdout
  $stdout = StringIO.new
  yield
  $stdout.string
ensure
  $stdout = old_stdout
end

# utility function to capture stderr
def capture_stderr
  old_stderr = $stderr
  $stderr = StringIO.new
  yield
  $stderr.string
ensure
  $stderr = old_stderr
end
