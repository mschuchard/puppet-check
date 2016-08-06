require_relative '../puppet-check'

# class to handle outputting diagnostic results in desired format
class OutputResults
  # output the results for the files that were requested to be checked
  def self.run(output_format)
    case output_format
    when 'text' then text
    when 'yaml' then yaml
    when 'json' then json
    end
  end

  # output the results as text
  def self.text
    unless PuppetCheck.error_files.empty?
      print "\033[31mThe following files have errors:\033[0m\n-- "
      puts PuppetCheck.error_files.join("\n\n-- ")
    end
    unless PuppetCheck.warning_files.empty?
      print "\n\033[33mThe following files have warnings:\033[0m\n-- "
      puts PuppetCheck.warning_files.join("\n\n-- ")
    end
    unless PuppetCheck.clean_files.empty?
      print "\n\033[32mThe following files have no errors or warnings:\033[0m\n-- "
      puts PuppetCheck.clean_files.join("\n-- ")
    end
    unless PuppetCheck.ignored_files.empty?
      print "\n\033[36mThe following files have unrecognized formats and therefore were not processed:\033[0m\n-- "
      puts PuppetCheck.ignored_files.join("\n-- ")
    end
  end

  # output the results as yaml
  def self.yaml
    hash = {}
    hash['errors'] = PuppetCheck.error_files unless PuppetCheck.error_files.empty?
    hash['warnings'] = PuppetCheck.warning_files unless PuppetCheck.warning_files.empty?
    hash['clean'] = PuppetCheck.clean_files unless PuppetCheck.clean_files.empty?
    hash['ignored'] = PuppetCheck.ignored_files unless PuppetCheck.ignored_files.empty?
    puts Psych.dump(hash, indentation: 2)
  end

  # output the results as json
  def self.json
    hash = {}
    hash['errors'] = PuppetCheck.error_files unless PuppetCheck.error_files.empty?
    hash['warnings'] = PuppetCheck.warning_files unless PuppetCheck.warning_files.empty?
    hash['clean'] = PuppetCheck.clean_files unless PuppetCheck.clean_files.empty?
    hash['ignored'] = PuppetCheck.ignored_files unless PuppetCheck.ignored_files.empty?
    puts JSON.pretty_generate(hash)
  end
end
