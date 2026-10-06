require_relative '../puppet_check'

# class to handle outputting diagnostic results in desired format
class OutputResults
  HEADER = {
    errors: "\033[31mThe following files have errors:\033[0m\n",
    warnings: "\033[33mThe following files have warnings:\033[0m\n",
    clean: "\033[32mThe following files have no errors or warnings:\033[0m\n-- ",
    ignored: "\033[36mThe following files have unrecognized formats and therefore were not processed:\033[0m\n-- "
  }.freeze

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
    when 'junit'
      junit(files)
    else
      raise "puppet-check: Unsupported output format '#{format}' was specified."
    end
  end

  # output the results as text
  private_class_method def self.text(files)
    # output text for each of four file categories
    %i[errors warnings clean ignored].each do |category|
      # immediately return if category is empty
      next unless files.key?(category)

      # display heading, files, and file messages per category for text formatting
      category_files = files[category]

      # display category heading
      print HEADER[category]

      # display files and optionally messages
      case category_files
      when Hash then category_files.each { |file, messages| puts "-- #{file}:\n#{messages.join("\n")}" }
      when Array then puts category_files.join("\n-- ")
      else raise "puppet-check: The files category was of unexpected type #{category_files.class}. Please file an issue with this log message, category heading, and information about the parsed files."
      end

      # newline between categories for easier visual parsing
      puts ''
    end
  end

  # output the results as junit xml
  private_class_method def self.junit(files)
    require 'rexml/document'

    # initialize four categories from input files
    errors = files.fetch(:errors, {})
    warnings = files.fetch(:warnings, {})
    clean = files.fetch(:clean, [])
    ignored = files.fetch(:ignored, [])

    # initialize junit document
    document = REXML::Document.new
    document << REXML::XMLDecl.new('1.0', 'UTF-8')
    suite = document.add_element('testsuite', 'name' => 'puppet-check', 'tests' => (errors.length + warnings.length + clean.length + ignored.length).to_s, 'failures' => errors.length.to_s, 'skipped' => ignored.length.to_s)

    # junit has no warning status, so errors are failures, warnings are passing tests with output, and ignored files are skipped
    errors.each { |file, messages| junit_testcase(suite, file).add_element('failure', 'message' => messages.first).text = messages.join("\n") }
    warnings.each { |file, messages| junit_testcase(suite, file).add_element('system-out').text = messages.join("\n") }
    clean.each { |file| junit_testcase(suite, file) }
    ignored.each { |file| junit_testcase(suite, file).add_element('skipped') }

    # write without added whitespace so that multi-line message text is preserved exactly
    REXML::Formatters::Default.new.write(document, $stdout)
    puts ''
  end

  # add a testcase element for a file to the test suite
  private_class_method def self.junit_testcase(suite, file)
    suite.add_element('testcase', 'classname' => 'puppet-check', 'name' => file)
  end
end
