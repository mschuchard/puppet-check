require_relative '../puppet-check'

# executes diagnostics on ruby files
class RubyParser
  # checks ruby syntax and style (.rb)
  def self.ruby(file)
    # check ruby syntax
    catch(:good) { instance_eval("BEGIN {throw :good}; #{File.read(file)}") }
  rescue ScriptError, StandardError => err
    PuppetCheck.error_files.push("-- #{file}:\n#{err}")
    # TODO: RC rescue warnings and dump in style array
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
        warnings += reek_warnings.split("\n")[1..-1].join("\n").strip unless reek_warnings == ''
      end

      # return warnings
      return PuppetCheck.warning_files.push("-- #{file}:\n#{warnings.strip}") unless warnings == ''
    end
    PuppetCheck.clean_files.push("-- #{file}")
  end

  # checks ruby template syntax (.erb)
  def self.template(file)
    require 'erb'

    # check ruby template syntax
    begin
      ERB.new(File.read(file), nil, '-').result
    # credits to gds-operations/puppet-syntax for errors to ignore
    rescue NameError, TypeError
    rescue ScriptError, StandardError => err
      return PuppetCheck.error_files.push("-- #{file}:\n#{err}")
      # TODO: RC rescue warnings and dump in style array
    end
    PuppetCheck.clean_files.push("-- #{file}")
  end

  # checks librarian puppet syntax (Puppetfile/Modulefile)
  def self.librarian(file)
    # check librarian puppet syntax
    catch(:good) { instance_eval("BEGIN {throw :good}; #{File.read(file)}") }
  rescue SyntaxError, LoadError, ArgumentError => err
    return PuppetCheck.error_files.push("-- #{file}:\n#{err}")
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
      return PuppetCheck.warning_files.push("-- #{file}:\n#{warnings.split("#{File.absolute_path(file)}:").join('')}") unless warnings.empty?
    end
    PuppetCheck.clean_files.push("-- #{file}")
  end
end

def capture_stdout
  old_stdout = $stdout
  $stdout = StringIO.new('', 'w')
  yield
  $stdout.string
ensure
  $stdout = old_stdout
end
