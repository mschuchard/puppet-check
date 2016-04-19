require 'puppet'
require 'puppet/face'
require 'puppet/pops'
# TODO: B place these four under style check bool somewhere
require 'puppet-lint'
require 'puppet-lint/optparser'
require 'rubocop'
begin
  # reek = true
  require 'reek'
rescue LoadError
  # reek = false
end
require 'erb'
require 'yaml'
require 'json'
# require 'metadata-json-lint/rake_task'

# class to do all the heavy-lifting with the syntax and style checks
class FrontendParser
  def initialize(args = [])
    # assign arg array
    @args = args
    # TODO: B add ARG parser method

    # initialize future parser and style check bools
    @future_parser = false
    @style_check = false

    # initialize style arg arrays
    @puppetlint_args = []
    @rubocop_args = []
    @reek_args = []

    # initialize file type arrays
    @all_files = []
    @puppet_files = []
    @puppet_template_files = []
    @ruby_files = []
    @ruby_template_files = []
    @yaml_files = []
    @json_files = []
    @librarian_files = []

    # initialize diagnostic output arrays
    @error_files = []
    @warning_files = []
    @clean_files = []
    @ignored_files = []
  end

  # TODO: B move all non parser stuff up into puppet-check main class
  # main runner for the frontend_parser
  def run(paths)
    # grab all of the files to be processed and categorize them
    parse_paths(paths)
    sort_input_files(@all_files)
    # pass the categorized files out to the parsers to determine their status
    # TODO: RC pass the arrays of files to each method instead of each file individually
    @puppet_files.each { |puppet_file| puppet_parser(puppet_file) }
    @puppet_template_files.each { |puppet_template_file| puppet_template_parser(puppet_template_file) }
    @ruby_files.each { |ruby_file| ruby_parser(ruby_file) }
    @ruby_template_files.each { |ruby_template_file| ruby_template_parser(ruby_template_file) }
    @yaml_files.each { |yaml_file| yaml_parser(yaml_file) }
    @json_files.each { |json_file| json_parser(json_file) }
    @librarian_files.each { |librarian_file| librarian_parser(librarian_file) }
    # output the diagnostic results
    output_results
  end

  # parse the paths and return the array of files
  def parse_paths(paths)
    paths.uniq.each { |path| File.directory?(path) ? @all_files.concat(Dir.glob("#{path}/**/*").select { |subpath| File.file? subpath }) : @all_files.push(path) }
    @all_files.uniq!
  end

  # sorts the files to be processed and returns them in categorized arrays
  def sort_input_files(input_files)
    input_files.each do |input_file|
      case input_file
      when /.*\.pp/ then @puppet_files.push(input_file)
      when /.*\.epp/ then @puppet_template_files.push(input_file)
      when /.*\.rb/ then @ruby_files.push(input_file)
      when /.*\.erb/ then @ruby_template_files.push(input_file)
      when /.*\.ya?ml/ then @yaml_files.push(input_file)
      when /.*\.json/ then @json_files.push(input_file)
      when 'Puppetfile', 'Modulefile' then @librarian_files.push(input_file)
      else @ignored_files.push(input_file)
      end
    end
  end

  # TODO: B make each of these methods their own class
  # checks puppet syntax and style (.pp)
  def puppet_parser(file)
    # we need this for 'reasons'
    Puppet.initialize_settings unless Puppet.settings.app_defaults_initialized?
    Puppet[:parser] = 'future' if @future_parser && (Puppet::PUPPETVERSION.to_i < 4)
    # check puppet syntax
    begin
      Puppet::Face[:parser, :current].validate(file)
    # prevent Puppet::Face from executing an exit that affects PuppetCheck
    rescue SystemExit
      @error_files.push("-- #{file}: has a syntax error")
      return
    # TODO: B get this capturing the error output; I think I need to redirect logging; update spec test when finished
    # Puppet::Util::Log.newdestination(Puppet::Test::LogCollector.new(output))
    # Puppet::Util::Log.level = :warning
    # Puppet::Util::Log.close_all
    rescue Puppet::ParseError => err
      @error_files.push("-- #{err}")
      return
    end
    # check puppet style
    if @style_check
      # check for invalid arguments to PuppetLint
      begin
        PuppetLint::OptParser.build.parse!(@puppetlint_args)
      rescue OptionParser::InvalidOption
        puts "puppet-lint: #{$ERROR_INFO.message}"
        return 1
      end
      # check the style
      puppet_lint = PuppetLint.new
      puppet_lint.file = file
      puppet_lint.run
      # catalog the warnings
      if puppet_lint.warnings?
        warning = "-- #{file}:"
        puppet_lint.problems.each { |values| warning += " #{values[:message]} at line #{values[:line]}, column #{values[:column]}\n" }
        @warning_files.push(warning)
        return
      end
    end
    @clean_files.push("-- #{file}")
  end

  # checks puppet teplate syntax (.epp)
  def puppet_template_parser(file)
    # puppet before version 4 cannot check template syntax
    if Puppet::PUPPETVERSION.to_i < 4
      @ignored_files.push("-- #{file}: ignored due to Puppet Agent < 4.0.0")
      return
    end

    # check puppet template syntax
    begin
      # credits to gds-operations/puppet-syntax for the parser function call
      Puppet::Pops::Parser::EvaluatingParser::EvaluatingEppParser.new.parse_file(file)
    rescue StandardError => err
      @error_files.push("-- #{file}: #{err}")
      return
    end

    @clean_files.push("-- #{file}")
  end

  # checks ruby syntax and style (.rb)
  def ruby_parser(file)
    # TODO: B instance_eval seems to actually execute the files despite it not being instance_exec
    # check ruby syntax
    begin
      instance_eval(File.read(file), file)
    rescue ScriptError, StandardError => err
      @error_files.push("-- #{err}")
      return
      # TODO: RC rescue warnings and dump in style array
    end
    # check ruby style
    if @style_check
      # check RuboCop and ignore stdout
      @rubocop_args.concat(['-o', '/dev/null', file])
      rubocop_result = RuboCop::CLI.new.run(@rubocop_args)
      # TODO: B capture style issues
      # check Reek
      # TODO: B add reek (spec test already exists)
      # if reek
      #
      # end
      # catalog the warnings; RuboCop exits with 1 iff style issues
      if rubocop_result == 1
        @warning_files.push("-- #{file}: has warnings")
        return
      end
    end
    @clean_files.push("-- #{file}")
  end

  # checks ruby template syntax (.erb)
  def ruby_template_parser(file)
    # check ruby template syntax
    begin
      ERB.new(File.read(file), nil, '-').result
    # credits to gds-operations/puppet-syntax for errors to ignore
    rescue NameError, TypeError
    rescue ScriptError, StandardError => err
      @error_files.push("-- #{file}: #{err}")
      return
      # TODO: RC rescue warnings and dump in style array
    end
    @clean_files.push("-- #{file}")
  end

  # checks yaml syntax (.yaml or .yml)
  def yaml_parser(file)
    # check yaml syntax
    begin
      YAML.load_file(file)
    rescue StandardError => err
      @error_files.push("-- #{err}")
      return
    end
    @clean_files.push("-- #{file}")
  end

  # checks json syntax (.json)
  # TODO: RC more checks if metadata.json
  def json_parser(file)
    # check json syntax
    begin
      JSON.parse(File.read(file))
    rescue JSON::ParserError => err
      @error_files.push("-- #{file}: #{err.to_s.lines.first}")
      return
    end
    # Rake::Task[:metadata_lint].invoke
    @clean_files.push("-- #{file}")
  end

  # checks Puppetfile/Modulefile syntax (Puppetfile/Modulefile)
  def librarian_parser(file)
    # check librarian puppet syntax
    begin
      # TODO: B instance_eval seems to actually execute the files despite it not being instance_exec
      instance_eval(File.read(file), file)
    # TODO: B revisit this once instance_eval is fixed; at the moment there is no 'mod' method so instance_eval throws NoMethodError
    rescue NoMethodError
    rescue SyntaxError, LoadError, ArgumentError => err
      @error_files.push("-- #{file}: #{err}")
      return
    end
    # check librarian puppet style
    if @style_check
      # check Rubocop and ignore stdout; RuboCop is confused about the first 'mod' argument in librarian puppet so disable the Style/FileName check
      @rubocop_args.include?('--except') ? @rubocop_args[@rubocop_args.index('--except') + 1] = "#{@rubocop_args[@rubocop_args.index('--except') + 1]},Style/FileName" : @rubocop_args.concat(['--except', 'Style/FileName'])
      @rubocop_args.concat(['-o', '/dev/null', file])
      rubocop_result = RuboCop::CLI.new.run(@rubocop_args)
      # TODO: B capture style issues
      # catalog style warnings; RuboCop exits with 1 iff style issues
      if rubocop_result == 1
        @warning_files.push("-- #{file}: has warnings")
        return
      end
    end
    @clean_files.push("-- #{file}")
  end

  # output the results for the files that were requested to be checked
  def output_results
    # output files with errors
    unless @error_files.empty?
      puts 'The following files have errors:'
      puts @error_files
    end
    # output files with warnings
    unless @warning_files.empty?
      puts 'The following files have warnings:'
      puts @warning_files
    end
    # output files with no issues
    unless @clean_files.empty?
      puts 'The following files processed with no errors or warnings:'
      puts @clean_files
    end
    # output files that were ignored
    unless @ignored_files.empty?
      puts 'The following files were unrecognized formats and therefore not processed:'
      puts @ignored_files
    end
  end
end
