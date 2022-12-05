require_relative '../puppet_check'

# class to handle outputting diagnostic results in desired format
class OutputResults
  # output the results as text
  def self.text
    # errors
    unless PuppetCheck.settings[:error_files].empty?
      puts "\033[31mThe following files have errors:\033[0m"
      PuppetCheck.settings[:error_files].each { |file, error| puts "-- #{file}: #{error}"}
    end
    # warnings
    unless PuppetCheck.settings[:warning_files].empty?
      print "\n\033[33mThe following files have warnings:\033[0m\n-- "
      puts PuppetCheck.settings[:warning_files].join("\n\n-- ")
    end
    # cleans
    unless PuppetCheck.settings[:clean_files].empty?
      print "\n\033[32mThe following files have no errors or warnings:\033[0m\n-- "
      puts PuppetCheck.settings[:clean_files].join("\n-- ")
    end
    # ignores
    return if PuppetCheck.settings[:ignored_files].empty?
    print "\n\033[36mThe following files have unrecognized formats and therefore were not processed:\033[0m\n-- "
    puts PuppetCheck.settings[:ignored_files].join("\n-- ")
  end

  # output the results as yaml or json
  def self.markup(format)
    # generate output hash
    hash = {}
    hash['errors'] = PuppetCheck.settings[:error_files] unless PuppetCheck.settings[:error_files].empty?
    hash['warnings'] = PuppetCheck.settings[:warning_files] unless PuppetCheck.settings[:warning_files].empty?
    hash['clean'] = PuppetCheck.settings[:clean_files] unless PuppetCheck.settings[:clean_files].empty?
    hash['ignored'] = PuppetCheck.settings[:ignored_files] unless PuppetCheck.settings[:ignored_files].empty?

    # convert hash to markup language
    case format
    when 'yaml'
      require 'yaml'
      puts Psych.dump(hash, indentation: 2)
    when 'json'
      require 'json'
      puts JSON.pretty_generate(hash)
    else
      raise "puppet-check: Unsupported output format '#{format}' was specified."
    end
  end
end
