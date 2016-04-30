# TODO: RC rearrange the init and run methods with each other

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

  # TODO: RC find a way to completely remove need for initialize and these vars
  def initialize
    # initialize file type arrays
    @puppet_manifests = []
    @puppet_templates = []
    @ruby_rubies = []
    @ruby_templates = []
    @data_yamls = []
    @data_jsons = []
    @ruby_librarians = []
  end

  # main runner for PuppetCheck
  def run(paths)
    # grab all of the files to be processed and categorize them
    all_files = parse_paths(paths)
    sort_input_files(all_files)

    # pass the categorized files out to the parsers to determine their status
    # TODO: RC pass the arrays of files to each method instead of each file individually
    @puppet_manifests.each { |manifest| PuppetParser.manifest(manifest) }
    @puppet_templates.each { |template| PuppetParser.template(template) }
    @ruby_rubies.each { |ruby| RubyParser.ruby(ruby) }
    @ruby_templates.each { |template| RubyParser.template(template) }
    @data_yamls.each { |yaml| DataParser.yaml(yaml) }
    @data_jsons.each { |json| DataParser.json(json) }
    @ruby_librarians.each { |librarian| RubyParser.librarian(librarian) }

    # output the diagnostic results
    self.class.output_results
  end

  # parse the paths and return the array of files
  def parse_paths(paths)
    all_files = []

    # traverse the unique paths, return all files, and replace // with /
    paths.uniq.each do |path|
      if File.directory?(path)
        all_files.concat(Dir.glob("#{path}/**/*").select { |subpath| File.file? subpath })
      else
        all_files.push(path)
      end
    end
    all_files.map { |file| file.gsub('//', '/') }

    # return unique files
    all_files.uniq
  end

  # sorts the files to be processed and returns them in categorized arrays
  def sort_input_files(input_files)
    input_files.each do |input_file|
      case input_file
      when /.*\.pp$/ then @puppet_manifests.push(input_file)
      when /.*\.epp$/ then @puppet_templates.push(input_file)
      when /.*\.rb$/ then @ruby_rubies.push(input_file)
      when /.*\.erb$/ then @ruby_templates.push(input_file)
      when /.*\.ya?ml$/ then @data_yamls.push(input_file)
      when /.*\.json$/ then @data_jsons.push(input_file)
      when /.*Puppetfile$/, /.*Modulefile$/ then @ruby_librarians.push(input_file)
      else self.class.ignored_files.push("-- #{input_file}")
      end
    end
  end

  # output the results for the files that were requested to be checked
  def self.output_results
    puts "\033[31mThe following files have errors:\033[0m", error_files unless error_files.empty?
    puts "\033[33mThe following files have warnings:\033[0m", warning_files unless warning_files.empty?
    puts "\033[32mThe following files have no errors or warnings:\033[0m", clean_files unless clean_files.empty?
    puts "\033[34mThe following files were unrecognized formats and therefore not processed:\033[0m", ignored_files unless ignored_files.empty?
  end
end
