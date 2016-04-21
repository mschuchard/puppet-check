# interfaces from CLI/tasks and to individual parsers
# TODO: RC rearrange the init and run methods with each other
# TODO: RC refactor the methods to reduce instance vars

require_relative 'puppet-check/puppet_parser'
require_relative 'puppet-check/ruby_parser'
require_relative 'puppet-check/data_parser'

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
  @reek_args = []

  # let the parser methods read user options and append to the file arrays; let CLI and tasks write to user options
  class << self
    attr_accessor :future_parser, :style_check, :error_files, :warning_files, :clean_files, :ignored_files, :puppetlint_args, :rubocop_args, :reek_args
  end

  # TODO: RC find a way to completely remove need for initialize and these vars
  def initialize
    # initialize file type arrays
    @all_files = []
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
    parse_paths(paths)
    sort_input_files(@all_files)
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
  def output_results
    # output files with errors
    puts "\033[31mThe following files have errors:\033[0m", self.class.error_files unless self.class.error_files.empty?
    # output files with warnings
    puts "\033[33mThe following files have warnings:\033[0m", self.class.warning_files unless self.class.warning_files.empty?
    # output files with no issues
    puts "\033[32mThe following files have no errors or warnings:\033[0m", self.class.clean_files unless self.class.clean_files.empty?
    # output files that were ignored
    puts "\033[34mThe following files were unrecognized formats and therefore not processed:\033[0m", self.class.ignored_files unless self.class.ignored_files.empty?
  end
end
