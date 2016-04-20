require_relative '../puppet-check'

# executes diagnostics on ruby files
class PuppetCheck::RubyParser
  # checks ruby syntax and style (.rb)
  def self.ruby(file, rubocop_args, reek_args)
    # TODO: B instance_eval seems to actually execute the files despite it not being instance_exec
    # check ruby syntax
    begin
      instance_eval(File.read(file), file)
    rescue ScriptError, StandardError => err
      PuppetCheck.error_files.push("-- #{err}")
      # TODO: RC rescue warnings and dump in style array
    else
      # check ruby style
      if PuppetCheck.style_check
        require 'rubocop'
        # check RuboCop and ignore stdout
        rubocop_args.concat(['-o', '/dev/null', file])
        # TODO: B capture style issues
        # check Reek
        begin
          require 'reek'
        rescue LoadError
        else
          # TODO: B add reek (spec test already exists)
        end
        # catalog the warnings; RuboCop exits with 1 iff style issues
        return PuppetCheck.warning_files.push("-- #{file}: has warnings") if RuboCop::CLI.new.run(rubocop_args) == 1
      end
      PuppetCheck.clean_files.push("-- #{file}")
    end
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
      return PuppetCheck.error_files.push("-- #{file}: #{err}")
      # TODO: RC rescue warnings and dump in style array
    end
    PuppetCheck.clean_files.push("-- #{file}")
  end

  # checks Puppetfile/Modulefile syntax (Puppetfile/Modulefile)
  def self.librarian(file, rubocop_args, reek_args)
    # check librarian puppet syntax
    begin
      # TODO: B instance_eval seems to actually execute the files despite it not being instance_exec
      instance_eval(File.read(file), file)
    # TODO: B revisit this once instance_eval is fixed; at the moment there is no 'mod' method so instance_eval throws NoMethodError
    rescue NoMethodError
    rescue SyntaxError, LoadError, ArgumentError => err
      return PuppetCheck.error_files.push("-- #{file}: #{err}")
    end
    # check librarian puppet style
    if PuppetCheck.style_check
      require 'rubocop'
      # check Rubocop and ignore stdout; RuboCop is confused about the first 'mod' argument in librarian puppet so disable the Style/FileName check
      rubocop_args.include?('--except') ? rubocop_args[rubocop_args.index('--except') + 1] = "#{rubocop_args[rubocop_args.index('--except') + 1]},Style/FileName" : rubocop_args.concat(['--except', 'Style/FileName'])
      rubocop_args.concat(['-o', '/dev/null', file])
      # TODO: B capture style issues
      # catalog style warnings; RuboCop exits with 1 iff style issues
      return PuppetCheck.warning_files.push("-- #{file}: has warnings") if RuboCop::CLI.new.run(rubocop_args) == 1
    end
    PuppetCheck.clean_files.push("-- #{file}")
  end
end
