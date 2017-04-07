require_relative 'puppet-check/puppet_parser'
require_relative 'puppet-check/ruby_parser'
require_relative 'puppet-check/data_parser'
require_relative 'puppet-check/output_results'
require_relative 'puppet-check/regression_check'

# interfaces from CLI/tasks and to individual parsers
class PuppetCheck
  # initialize future parser, style check, and regression check bools
  @future_parser = false
  @style_check = false
  @smoke_check = false
  @regression_check = false

  # initialize output format option
  @output_format = 'text'

  # initialize octocatalog-diff options
  @octoconfig = '.octocatalog-diff.cfg.rb'
  @octonodes = %w(localhost.localdomain)

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
    attr_accessor :future_parser, :style_check, :smoke_check, :regression_check, :output_format, :octoconfig, :octonodes, :error_files, :warning_files, :clean_files, :ignored_files, :puppetlint_args, :rubocop_args
  end

  # main runner for PuppetCheck
  def run(paths)
    # grab all of the files to be processed
    files = self.class.parse_paths(paths)

    # parse the files
    execute_parsers(files, self.class.future_parser, self.class.style_check, self.class.puppetlint_args, self.class.rubocop_args)

    # output the diagnostic results
    PuppetCheck.output_format == 'text' ? OutputResults.text : OutputResults.markup

    # perform regression checks if there were no errors and the user desires
    RegressionCheck.smoke(self.class.octonodes, self.class.octoconfig) if self.class.error_files.empty? && PuppetCheck.smoke_check

    # perform regression checks if there were no errors and the user desires
    RegressionCheck.regression(self.class.octonodes, self.class.octoconfig) if self.class.error_files.empty? && PuppetCheck.regression_check

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
  def execute_parsers(files, future, style, pl_args, rc_args)
    PuppetParser.manifest(files.select { |file| File.extname(file) == '.pp' }, future, style, pl_args)
    files.reject! { |file| File.extname(file) == '.pp' }
    PuppetParser.template(files.select { |file| File.extname(file) == '.epp' })
    files.reject! { |file| File.extname(file) == '.epp' }
    RubyParser.ruby(files.select { |file| File.extname(file) == '.rb' }, style, rc_args)
    files.reject! { |file| File.extname(file) == '.rb' }
    RubyParser.template(files.select { |file| File.extname(file) == '.erb' })
    files.reject! { |file| File.extname(file) == '.erb' }
    DataParser.yaml(files.select { |file| File.extname(file) =~ /\.ya?ml$/ })
    files.reject! { |file| File.extname(file) =~ /\.ya?ml$/ }
    DataParser.json(files.select { |file| File.extname(file) == '.json' })
    files.reject! { |file| File.extname(file) == '.json' }
    RubyParser.librarian(files.select { |file| File.basename(file) =~ /(?:Puppet|Module|Rake|Gem)file$/ }, style, rc_args)
    files.reject! { |file| File.basename(file) =~ /(?:Puppet|Module|Rake|Gem)file$/ }
    files.each { |file| self.class.ignored_files.push(file.to_s) }
  end
end
