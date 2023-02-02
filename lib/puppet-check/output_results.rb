require_relative '../puppet_check'

# class to handle outputting diagnostic results in desired format
class OutputResults
  # output the results as text
  def self.text
    # errors
    unless PuppetCheck.files[:errors].empty?
      puts "\033[31mThe following files have errors:\033[0m"
      PuppetCheck.files[:errors].each { |file, errors| puts "-- #{file}:\n#{errors.join("\n")}" }
    end
    # warnings
    unless PuppetCheck.files[:warnings].empty?
      puts "\n\033[33mThe following files have warnings:\033[0m"
      PuppetCheck.files[:warnings].each { |file, warnings| puts "-- #{file}:\n#{warnings.join("\n")}" }
    end
    # cleans
    unless PuppetCheck.files[:clean].empty?
      print "\n\033[32mThe following files have no errors or warnings:\033[0m\n-- "
      puts PuppetCheck.files[:clean].join("\n-- ")
    end
    # ignores
    return if PuppetCheck.files[:ignored].empty?
    print "\n\033[36mThe following files have unrecognized formats and therefore were not processed:\033[0m\n-- "
    puts PuppetCheck.files[:ignored].join("\n-- ")
  end

  # output the results as yaml or json
  def self.markup(format)
    # generate output hash
    hash = {}
    hash['errors'] = PuppetCheck.files[:errors] unless PuppetCheck.files[:errors].empty?
    hash['warnings'] = PuppetCheck.files[:warnings] unless PuppetCheck.files[:warnings].empty?
    hash['clean'] = PuppetCheck.files[:clean] unless PuppetCheck.files[:clean].empty?
    hash['ignored'] = PuppetCheck.files[:ignored] unless PuppetCheck.files[:ignored].empty?

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
