require_relative '../puppet_check'

# class to handle outputting diagnostic results in desired format
class OutputResults
  # output the results in various formats
  def self.run(files, format)
    # remove empty entries
    files.delete_if { |_, sorted_files| sorted_files.empty? }

    # output hash according to specified format
    case format
    when 'text'
      text(files)
    when 'yaml'
      require 'yaml'
      # maintain filename format consistency among output formats
      files.transform_keys!(&:to_s)
      puts Psych.dump(files, indentation: 2)
    when 'json'
      require 'json'
      puts JSON.pretty_generate(files)
    else
      raise "puppet-check: Unsupported output format '#{format}' was specified."
    end
  end

  # output the results as text
  def self.text(files)
    private_class_method :method

    # errors
    if files.key?(:errors)
      puts "\033[31mThe following files have errors:\033[0m"
      files[:errors].each { |file, errors| puts "-- #{file}:\n#{errors.join("\n")}" }
    end
    # warnings
    if files.key?(:warnings)
      puts "\n\033[33mThe following files have warnings:\033[0m"
      files[:warnings].each { |file, warnings| puts "-- #{file}:\n#{warnings.join("\n")}" }
    end
    # cleans
    if files.key?(:clean)
      print "\n\033[32mThe following files have no errors or warnings:\033[0m\n-- "
      puts files[:clean].join("\n-- ")
    end
    # ignores
    return unless files.key?(:ignored)
    print "\n\033[36mThe following files have unrecognized formats and therefore were not processed:\033[0m\n-- "
    puts files[:ignored].join("\n-- ")
  end
end
