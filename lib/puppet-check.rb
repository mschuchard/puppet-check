require_relative 'puppet-check/puppet_parser'
require_relative 'puppet-check/ruby_parser'
require_relative 'puppet-check/data_parser'

# interfaces from CLI/tasks and to individual parsers
class PuppetCheck
  # initialize future parser and style check bools
  @future_parser = false
  @style_check = false

  # initialize output format option
  @output_format = 'text'

  # initialize diagnostic output arrays
  @error_files = []
  @warning_files = []
  @clean_files = []
  @ignored_files = []

  # initialize style arg arrays
  @puppetlint_args = []
  @rubocop_args = []

  # allow the parser methods read user options and append to the file arrays; allow CLI and tasks write to user options
  class << self
    attr_accessor :future_parser, :style_check, :output_format, :error_files, :warning_files, :clean_files, :ignored_files, :puppetlint_args, :rubocop_args
  end

  # main runner for PuppetCheck
  def run(paths)
    # grab all of the files to be processed
    files = self.class.parse_paths(paths)

    # parse the files
    execute_parsers(files)

    # output the diagnostic results
    self.class.output_results

    # exit code
    self.class.error_files.empty? ? 0 : 2
  end

  # parse the paths and return the array of files
  def self.parse_paths(paths)
    files = []

    # traverse the unique paths and return all files
    paths.uniq.each do |path|
      if File.directory?(path)
        files.concat(Dir.glob("#{path}/**/*").select { |subpath| File.file? subpath })
      elsif File.file?(path)
        files.push(path)
      end
    end

    # do not process fixtures, check that at least one file was found, and remove double slashes
    files.reject! { |file| file =~ /fixtures/ }
    raise "puppet-check: no files found in supplied paths #{paths.join(', ')}." if files.empty?
    files.map! { |file| file.gsub('//', '/') }

    files.uniq
  end

  # categorize and pass the files out to the parsers to determine their status
  def execute_parsers(files)
    PuppetParser.manifest(files.select { |file| File.extname(file) == '.pp' })
    files.reject! { |file| File.extname(file) == '.pp' }
    PuppetParser.template(files.select { |file| File.extname(file) == '.epp' })
    files.reject! { |file| File.extname(file) == '.epp' }
    RubyParser.ruby(files.select { |file| File.extname(file) == '.rb' })
    files.reject! { |file| File.extname(file) == '.rb' }
    RubyParser.template(files.select { |file| File.extname(file) == '.erb' })
    files.reject! { |file| File.extname(file) == '.erb' }
    DataParser.yaml(files.select { |file| File.extname(file) =~ /\.ya?ml$/ })
    files.reject! { |file| File.extname(file) =~ /\.ya?ml$/ }
    DataParser.json(files.select { |file| File.extname(file) == '.json' })
    files.reject! { |file| File.extname(file) == '.json' }
    RubyParser.librarian(files.select { |file| File.basename(file) =~ /(?:Puppet|Module|Rake|Gem)file$/ })
    files.reject! { |file| File.basename(file) =~ /(?:Puppet|Module|Rake|Gem)file$/ }
    files.each { |file| self.class.ignored_files.push("-- #{file}") }
  end

  # output the results for the files that were requested to be checked
  def self.output_results
    case output_format
    when 'text' then output_results_text
    when 'yaml' then output_results_yaml
    when 'json' then output_results_json
    end
  end

  # output the results as text
  def self.output_results_text
    unless error_files.empty?
      print "\033[31mThe following files have errors:\033[0m\n-- "
      puts error_files.join("\n\n-- ")
    end
    unless warning_files.empty?
      print "\n\033[33mThe following files have warnings:\033[0m\n-- "
      puts warning_files.join("\n\n-- ")
    end
    unless clean_files.empty?
      print "\n\033[32mThe following files have no errors or warnings:\033[0m\n-- "
      puts clean_files.join("\n-- ")
    end
    unless ignored_files.empty?
      print "\n\033[36mThe following files have unrecognized formats and therefore were not processed:\033[0m\n-- "
      puts ignored_files.join("\n-- ")
    end
  end

  # output the results as yaml
  def self.output_results_yaml
    hash = {}
    hash['errors'] = error_files unless error_files.empty?
    hash['warnings'] = warning_files unless warning_files.empty?
    hash['clean'] = clean_files unless clean_files.empty?
    hash['ignored'] = ignored_files unless ignored_files.empty?
    puts Psych.dump(hash, indentation: 2)
  end

  # output the results as json
  def self.output_results_json
    hash = {}
    hash['errors'] = error_files unless error_files.empty?
    hash['warnings'] = warning_files unless warning_files.empty?
    hash['clean'] = clean_files unless clean_files.empty?
    hash['ignored'] = ignored_files unless ignored_files.empty?
    puts JSON.pretty_generate(hash)
  end
end
