require_relative 'puppet-check/puppet_parser'
require_relative 'puppet-check/ruby_parser'
require_relative 'puppet-check/data_parser'
require_relative 'puppet-check/output_results'

# interfaces from CLI/tasks and to individual parsers
class PuppetCheck
  # initialize settings hash
  @settings = {}

  # allow the parser methods read user options and append to the file arrays; allow CLI and tasks write to user options
  class << self
    attr_accessor :settings
  end

  # main runner for PuppetCheck
  def run(settings, paths)
    # establish settings
    self.class.settings = settings

    # settings defaults
    self.class.defaults

    # grab all of the files to be processed
    files = self.class.parse_paths(paths)

    # parse the files
    execute_parsers(files, settings[:future_parser], settings[:style_check], settings[:public], settings[:private], settings[:puppetlint_args], settings[:rubocop_args])

    # output the diagnostic results
    settings[:output_format] == 'text' ? OutputResults.text : OutputResults.markup

    # progress to regression checks if no errors in file checks
    if self.class.settings[:error_files].empty? && (!self.class.settings[:fail_on_warning] || self.class.settings[:warning_files].empty?)
      begin
        require_relative 'puppet-check/regression_check'
      # if octocatalog-diff is not installed then return immediately
      rescue LoadError
        return 0
      end

      # perform smoke checks if there were no errors and the user desires
      begin
        catalog = RegressionCheck.smoke(settings[:octonodes], settings[:octoconfig]) if settings[:smoke_check]
      # smoke check failure? output message and return 2
      rescue OctocatalogDiff::Errors::CatalogError => err
        puts 'There was a smoke check error:'
        puts err
        puts catalog.error_message unless catalog.valid?
        2
      end
      # perform regression checks if there were no errors and the user desires
      # begin
      #   catalog = RegressionCheck.regression(settings[:octonodes], settings[:octoconfig]) if settings[:regression_check]
      # rescue OctocatalogDiff::Errors::CatalogError => err
      #   puts 'There was a catalog compilation error during the regression check:'
      #   puts err
      #   puts catalog.error_message unless catalog.valid?
      #   2
      # end
      # code to output differences in catalog?
      # everything passed? return 0
      0
    else
      # error files? return 2
      2
    end
  end

  # establish default settings
  def self.defaults
    # initialize future parser, fail on warning,  style check, and regression check bools
    @settings[:future_parser] ||= false
    @settings[:fail_on_warning] ||= false
    @settings[:style_check] ||= false
    @settings[:smoke_check] ||= false
    @settings[:regression_check] ||= false

    # initialize ssl keys for eyaml checks
    @settings[:public] ||= nil
    @settings[:private] ||= nil

    # initialize output format option
    @settings[:output_format] ||= 'text'

    # initialize diagnostic output arrays
    @settings[:error_files] ||= []
    @settings[:warning_files] ||= []
    @settings[:clean_files] ||= []
    @settings[:ignored_files] ||= []

    # initialize octocatalog-diff options
    @settings[:octoconfig] ||= '.octocatalog-diff.cfg.rb'
    @settings[:octonodes] ||= %w[localhost.localdomain]

    # initialize style arg arrays
    @settings[:puppetlint_args] ||= []
    @settings[:rubocop_args] ||= []
  end

  # parse the paths and return the array of files
  def self.parse_paths(paths)
    files = []

    # traverse the unique paths and return all files
    paths.uniq.each do |path|
      if File.directory?(path)
        files.concat(Dir.glob("#{path}/**/*").select { |subpath| File.file?(subpath) })
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
  def execute_parsers(files, future, style, public, private, pl_args, rc_args)
    # check manifests
    manifests, files = files.partition { |file| File.extname(file) == '.pp' }
    PuppetParser.manifest(manifests, future, style, pl_args) unless manifests.empty?
    # check puppet templates
    templates, files = files.partition { |file| File.extname(file) == '.epp' }
    PuppetParser.template(templates) unless templates.empty?
    # check ruby files
    rubies, files = files.partition { |file| File.extname(file) == '.rb' }
    RubyParser.ruby(rubies, style, rc_args) unless rubies.empty?
    # check ruby templates
    templates, files = files.partition { |file| File.extname(file) == '.erb' }
    RubyParser.template(templates) unless templates.empty?
    # check yaml data
    yamls, files = files.partition { |file| File.extname(file) =~ /\.ya?ml$/ }
    DataParser.yaml(yamls) unless yamls.empty?
    # check json data
    jsons, files = files.partition { |file| File.extname(file) == '.json' }
    DataParser.json(jsons) unless jsons.empty?
    # check eyaml data; block this for now
    # eyamls, files = files.partition { |file| File.extname(file) =~ /\.eya?ml$/ }
    # DataParser.eyaml(eyamls, public, private) unless eyamls.empty?
    # check misc ruby
    librarians, files = files.partition { |file| File.basename(file) =~ /(?:Puppet|Module|Rake|Gem)file$/ }
    RubyParser.librarian(librarians, style, rc_args) unless librarians.empty?
    # ignore everything else
    self.class.settings[:ignored_files].concat(files)
  end
end
