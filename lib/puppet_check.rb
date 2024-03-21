require_relative 'puppet-check/puppet_parser'
require_relative 'puppet-check/ruby_parser'
require_relative 'puppet-check/data_parser'
require_relative 'puppet-check/output_results'

# interfaces from CLI/tasks and to individual parsers
class PuppetCheck
  # initialize files hash
  @files = {
    errors: {},
    warnings: {},
    clean: [],
    ignored: []
  }

  # allow the parser methods to write to the files
  class << self
    attr_accessor :files
  end

  # main runner for PuppetCheck
  def run(settings = {}, paths = [])
    # settings defaults
    settings = self.class.defaults(settings)

    # grab all of the files to be processed
    files = self.class.parse_paths(paths)

    # parse the files
    parsed_files = execute_parsers(files, settings[:style], settings[:puppetlint_args], settings[:rubocop_args], settings[:public], settings[:private])

    # output the diagnostic results
    OutputResults.run(parsed_files.clone, settings[:output_format])

    # progress to regression checks if no errors in file checks
    if parsed_files[:errors].empty? && (!settings[:fail_on_warning] || parsed_files[:warnings].empty?)
      begin
        require_relative 'puppet-check/regression_check'
      # if octocatalog-diff is not installed then return immediately
      rescue LoadError
        warn 'octocatalog-diff is not installed, and therefore the regressions check will be skipped'
        return 0
      end

      # perform smoke checks if there were no errors and the user desires
      begin
        catalog = RegressionCheck.smoke(settings[:octonodes], settings[:octoconfig]) if settings[:smoke]
      # smoke check failure? output message and return 2
      rescue OctocatalogDiff::Errors::CatalogError => err
        puts 'There was a smoke check error:'
        puts err
        puts catalog.error_message unless catalog.valid?
        2
      end
      # perform regression checks if there were no errors and the user desires
      # begin
      #   catalog = RegressionCheck.regression(settings[:octonodes], settings[:octoconfig]) if settings[:regression]
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
  def self.defaults(settings = {})
    private_class_method :method
    # initialize fail on warning,  style check, and regression check bools
    settings[:fail_on_warning] ||= false
    settings[:style] ||= false
    settings[:smoke] ||= false
    settings[:regression] ||= false

    # initialize ssl keys for eyaml checks
    settings[:public] ||= nil
    settings[:private] ||= nil

    # initialize output format option
    settings[:output_format] ||= 'text'

    # initialize octocatalog-diff options
    settings[:octoconfig] ||= '.octocatalog-diff.cfg.rb'
    settings[:octonodes] ||= %w[localhost.localdomain]

    # initialize style arg arrays
    settings[:puppetlint_args] ||= []
    settings[:rubocop_args] ||= []

    # return update settings
    settings
  end

  # parse the paths and return the array of files
  def self.parse_paths(paths = [])
    private_class_method :method
    files = []

    # traverse the unique paths and return all files not explicitly in fixtures
    paths.uniq.each do |path|
      if File.directory?(path)
        # glob all files in directory and concat them
        files.concat(Dir.glob("#{path}/**/*").select { |subpath| File.file?(subpath) && !subpath.include?('fixtures') })
      elsif File.file?(path) && !path.include?('fixtures')
        files.push(path)
      else
        warn "puppet-check: #{path} is not a directory, file, or symlink, and will not be considered during parsing"
      end
    end

    # check that at least one file was found, and remove double slashes from returned array
    raise "puppet-check: no files found in supplied paths '#{paths.join(', ')}'." if files.empty?
    files.map { |file| file.gsub('//', '/') }.uniq
  end

  private

  # categorize and pass the files out to the parsers to determine their status
  def execute_parsers(files, style, puppetlint_args, rubocop_args, public, private)
    # check manifests
    manifests, files = files.partition { |file| File.extname(file) == '.pp' }
    PuppetParser.manifest(manifests, style, puppetlint_args) unless manifests.empty?
    # check puppet templates
    templates, files = files.partition { |file| File.extname(file) == '.epp' }
    PuppetParser.template(templates) unless templates.empty?
    # check ruby files
    rubies, files = files.partition { |file| File.extname(file) == '.rb' }
    RubyParser.ruby(rubies, style, rubocop_args) unless rubies.empty?
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
    eyamls, files = files.partition { |file| File.extname(file) =~ /\.eya?ml$/ }
    DataParser.eyaml(eyamls, public, private) unless eyamls.empty?
    # check misc ruby
    librarians, files = files.partition { |file| File.basename(file) =~ /(?:Puppet|Module|Rake|Gem)file$/ }
    RubyParser.librarian(librarians, style, rubocop_args) unless librarians.empty?
    # ignore everything else
    files.each { |file| self.class.files[:ignored].push(file.to_s) }
    # return PuppetCheck.files to mitigate singleton write accessor side effects
    PuppetCheck.files
  end
end
