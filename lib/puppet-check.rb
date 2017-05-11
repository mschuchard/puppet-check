require_relative 'puppet-check/puppet_parser'
require_relative 'puppet-check/ruby_parser'
require_relative 'puppet-check/data_parser'
require_relative 'puppet-check/output_results'

# interfaces from CLI/tasks and to individual parsers
class PuppetCheck
  # initialize settings hash
  @settings = {}

  # initialize future parser, style check, and regression check bools
  @settings['future_parser'] = false
  @settings['style_check'] = false
  @settings['smoke_check'] = false
  @settings['regression_check'] = false

  # initialize output format option
  @settings['output_format'] = 'text'

  # initialize octocatalog-diff options
  @settings['octoconfig'] = '.octocatalog-diff.cfg.rb'
  @settings['octonodes'] = %w[localhost.localdomain]

  # initialize diagnostic output arrays
  @settings['error_files'] = []
  @settings['warning_files'] = []
  @settings['clean_files'] = []
  @settings['ignored_files'] = []

  # initialize style arg arrays
  @settings['puppetlint_args'] = []
  @settings['rubocop_args'] = []

  # allow the parser methods read user options and append to the file arrays; allow CLI and tasks write to user options
  class << self
    attr_accessor :settings
  end

  # main runner for PuppetCheck
  def run(paths)
    # grab all of the files to be processed
    files = self.class.parse_paths(paths)

    # parse the files
    execute_parsers(files, self.class.settings['future_parser'], self.class.settings['style_check'], self.class.settings['puppetlint_args'], self.class.settings['rubocop_args'])

    # output the diagnostic results
    PuppetCheck.settings['output_format'] == 'text' ? OutputResults.text : OutputResults.markup

    if self.class.settings['error_files'].empty?
      begin
        require_relative 'puppet-check/regression_check'
      rescue LoadError
      end

      # perform smoke checks if there were no errors and the user desires
      begin
        RegressionCheck.smoke(self.class.octonodes, self.class.octoconfig) if PuppetCheck.settings['smoke_check']
      # smoke check failure? output message and return 2
      rescue OctocatalogDiff::Errors::CatalogError => err
        puts 'There was a smoke check error:'
        puts err
        2
      end
      # perform regression checks if there were no errors and the user desires
      # begin
      #   RegressionCheck.regression(self.class.octonodes, self.class.octoconfig) if PuppetCheck.settings['regression_check']
      # rescue OctocatalogDiff::Errors::CatalogError => err
      #   puts 'There was a catalog compilation error during the regression check:'
      #   puts err
      #   2
      # enddarkness nova
      # code to output differences in catalog?
      # everything passed? return 0
      0
    else
      # error files? return 2
      2
    end
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
    files.each { |file| self.class.settings['ignored_files'].push(file.to_s) }
  end
end
