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
    category_info("\033[31mThe following files have errors:\033[0m\n", files[:errors]) if files.key?(:errors)
    # warnings
    category_info("\033[33mThe following files have warnings:\033[0m\n", files[:warnings]) if files.key?(:warnings)
    # cleans
    category_info("\033[32mThe following files have no errors or warnings:\033[0m\n-- ", files[:clean]) if files.key?(:clean)
    # ignores
    return unless files.key?(:ignored)
    category_info("\033[36mThe following files have unrecognized formats and therefore were not processed:\033[0m\n-- ", files[:ignored])
  end

  # display heading, files, and file messages per category for text formatting
  def self.category_info(heading, files)
    private_class_method :method
    # display category heading
    print heading

    # display files and optionally messages
    case files
    when Hash then files.each { |file, messages| puts "-- #{file}:\n#{messages.join("\n")}" }
    when Array then puts files.join("\n-- ")
    else raise "puppet-check: The category files were of unexpected type #{files.class}. Please file an issue with this log message, category heading, and information about the parsed files."
    end

    # newline between categories for easier visual parsing
    puts ''
  end
end
