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
    if parsed_files[:errors].empty? && (!settings[:fail_on_warnings] || parsed_files[:warnings].empty?)
      begin
        require_relative 'puppet-check/regression_check'

        # perform smoke checks if there were no errors and the user desires
        catalog = RegressionCheck.smoke(settings[:octonodes], settings[:octoconfig]) if settings[:smoke]
      # if octocatalog-diff is not installed then continue immediately
      rescue NameError
        puts 'puppet-check: immediately continuing to results'
        0
      # smoke check failure? output message and return 2
      rescue OctocatalogDiff::Errors::CatalogError => err
        puts 'There was a smoke check error:'
        puts err
        puts catalog.error_message unless catalog.valid?
        2
      else
        0
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
    else
      # error files? return 2
      2
    end
  end

  private

  # establish default settings
  def self.defaults(settings = {})
    # return settings with defaults where unspecified
    {
      # initialize fail on warning,  style check, and regression check bools
      fail_on_warnings: false,
      style: false,
      smoke: false,
      regression: false,
      # initialize ssl keys for eyaml checks
      public: nil,
      private: nil,
      # initialize output format option
      output_format: 'text',
      # initialize octocatalog-diff options
      octoconfig: '.octocatalog-diff.cfg.rb',
      octonodes: %w[localhost.localdomain],
      # initialize style arg arrays
      puppetlint_args: [],
      rubocop_args: []
    }.merge(settings)
  end

  # parse the paths and return the array of files
  def self.parse_paths(paths = [])
    files = []

    # traverse the unique paths and return all files not explicitly in fixtures
    paths.uniq.each do |path|
      if File.directory?(path)
        # glob all files in directory and concat them
        files.concat(Dir.glob("#{path}/**/*").select { |subpath| File.file?(subpath) && File.readable?(subpath) && !subpath.include?('fixtures') })
      elsif File.file?(path) && File.readable?(path) && !path.include?('fixtures')
        files.push(path)
      else
        warn "puppet-check: #{path} is not a readable directory, file, or symlink, and will not be considered during parsing"
      end
    end

    # check that at least one file was found, and remove double slashes from returned array
    raise "puppet-check: no files found in supplied paths '#{paths.join(', ')}'." if files.empty?
    files.map { |file| file.gsub('//', '/') }.uniq
  end

  # categorize and pass the files out to the parsers to determine their status
  def execute_parsers(files, style, puppetlint_args, rubocop_args, public, private)
    # check manifests
    manifests, files = files.partition { |file| File.extname(file) == '.pp' }
    # check puppet templates
    epp, files = files.partition { |file| File.extname(file) == '.epp' }
    # check ruby files
    rubies, files = files.partition { |file| File.extname(file) == '.rb' }
    # check ruby templates
    erb, files = files.partition { |file| File.extname(file) == '.erb' }
    # check yaml data
    yamls, files = files.partition { |file| File.extname(file) =~ /\.ya?ml$/ }
    # check json data
    jsons, files = files.partition { |file| File.extname(file) == '.json' }
    # check eyaml data
    eyamls, files = files.partition { |file| File.extname(file) =~ /\.eya?ml$/ }
    # check misc ruby
    librarians, files = files.partition { |file| File.basename(file) =~ /^(?:Puppet|Module|Rake|Gem|Vagrant)file|\.gemspec$/ && File.extname(file) != '.lock' }
    # ignore everything else
    files.each { |file| self.class.files[:ignored].push(file.to_s) }

    if Process.respond_to?(:fork)
      execute_parsers_parallel(manifests, epp, rubies, erb, yamls, jsons, eyamls, librarians, style, puppetlint_args, rubocop_args, public, private)
    else
      execute_parsers_sequential(manifests, epp, rubies, erb, yamls, jsons, eyamls, librarians, style, puppetlint_args, rubocop_args, public, private)
    end
  end

  private

  # sequential parser execution for systems that do not support Process.fork
  def execute_parsers_sequential(manifests, epp, rubies, erb, yamls, jsons, eyamls, librarians, style, puppetlint_args, rubocop_args, public, private)
    # perform file checks for each type
    PuppetParser.manifest(manifests, style, puppetlint_args) unless manifests.empty?
    PuppetParser.template(epp) unless epp.empty?
    RubyParser.ruby(rubies, style, rubocop_args) unless rubies.empty?
    RubyParser.template(erb) unless erb.empty?
    DataParser.yaml(yamls) unless yamls.empty?
    DataParser.json(jsons) unless jsons.empty?
    DataParser.eyaml(eyamls, public, private) unless eyamls.empty?
    RubyParser.librarian(librarians, style, rubocop_args) unless librarians.empty?
    # return PuppetCheck.files to mitigate singleton write accessor side effects
    PuppetCheck.files
  end

  # parallel parser execution for systems that support Process.fork
  def execute_parsers_parallel(manifests, epp, rubies, erb, yamls, jsons, eyamls, librarians, style, puppetlint_args, rubocop_args, public, private)
    # define jobs for parallel execution between different file types
    jobs = [
      manifests.empty? ? nil : -> { PuppetParser.manifest(manifests, style, puppetlint_args) },
      epp.empty? ? nil : -> { PuppetParser.template(epp) },
      rubies.empty? ? nil : -> { RubyParser.ruby(rubies, style, rubocop_args) },
      erb.empty? ? nil : -> { RubyParser.template(erb) },
      yamls.empty? ? nil : -> { DataParser.yaml(yamls) },
      jsons.empty? ? nil : -> { DataParser.json(jsons) },
      eyamls.empty? ? nil : -> { DataParser.eyaml(eyamls, public, private) },
      librarians.empty? ? nil : -> { RubyParser.librarian(librarians, style, rubocop_args) }
    ].compact

    # short circuit if no jobs to execute
    return PuppetCheck.files if jobs.empty?

    # initialize merged results hash to collect results from each forked process
    merged = { errors: {}, warnings: {}, clean: [], ignored: self.class.files[:ignored] }

    # TODO
    pipes = jobs.map do |job|
      reader, writer = IO.pipe
      pid = Process.fork do
        reader.close
        job.call
        writer.write(Marshal.dump(PuppetCheck.files))
        writer.close
      end
      writer.close
      [pid, reader]
    end

    # TODO
    pipes.each do |pid, reader|
      begin
        data = reader.read
        result = Marshal.load(data)
        merged[:errors].merge!(result[:errors])
        merged[:warnings].merge!(result[:warnings])
        merged[:clean].concat(result[:clean])
      ensure
        reader.close unless reader.closed?
        Process.wait(pid)
      end
    end

    # TODO
    self.class.files = merged
    PuppetCheck.files
  end
end
