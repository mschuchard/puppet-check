require_relative 'puppet-check/puppet_parser'
require_relative 'puppet-check/ruby_parser'
require_relative 'puppet-check/data_parser'

# interfaces from CLI/tasks and to individual parsers
class PuppetCheck
  # initialize future parser and style check bools
  @future_parser = false
  @style_check = false

  # initialize diagnostic output arrays
  @error_files = []
  @warning_files = []
  @clean_files = []
  @ignored_files = []

  # initialize style arg arrays
  @puppetlint_args = []
  @rubocop_args = []

  # let the parser methods read user options and append to the file arrays; let CLI and tasks write to user options
  class << self
    attr_accessor :future_parser, :style_check, :error_files, :warning_files, :clean_files, :ignored_files, :puppetlint_args, :rubocop_args
  end

  # main runner for PuppetCheck
  def run(paths)
    # grab all of the files to be processed
    files = parse_paths(paths)

    # parse the files
    execute_parsers(files)

    # output the diagnostic results
    self.class.output_results
  end

  # parse the paths and return the array of files
  def parse_paths(paths)
    files = []

    # traverse the unique paths, return all files, and replace // with /
    paths.uniq.each do |path|
      if File.directory?(path)
        files.concat(Dir.glob("#{path}/**/*").select { |subpath| File.file? subpath })
      elsif File.file?(path)
        files.push(path)
      end
    end

    # check that at least one file was found, remove double slashes, and return unique files
    raise "No files found in supplied paths #{paths.join(', ')}." if files.empty?
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
    DataParser.yaml(files.select { |file| file =~ /.*\.ya?ml$/ })
    files.reject! { |file| file =~ /.*\.ya?ml$/ }
    DataParser.json(files.select { |file| File.extname(file) == '.json' })
    files.reject! { |file| File.extname(file) == '.json' }
    RubyParser.librarian(files.select { |file| file =~ /.*(Puppet|Module|Rake|Gem)file$/ })
    files.reject! { |file| file =~ /.*(?:Puppet|Module|Rake|Gem)file$/ }
    files.each { |file| self.class.ignored_files.push("-- #{file}") }
  end

  # output the results for the files that were requested to be checked
  def self.output_results
    puts "\033[31mThe following files have errors:\033[0m", error_files.join("\n\n") unless error_files.empty?
    puts "\n\033[33mThe following files have warnings:\033[0m", warning_files.join("\n\n") unless warning_files.empty?
    puts "\n\033[32mThe following files have no errors or warnings:\033[0m", clean_files unless clean_files.empty?
    puts "\n\033[34mThe following files have unrecognized formats and therefore were not processed:\033[0m", ignored_files unless ignored_files.empty?
  end
end
