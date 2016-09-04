require_relative '../puppet-check'

# executes diagnostics on data files
class DataParser
  # checks yaml (.yaml/.yml)
  def self.yaml(files)
    require 'yaml'

    files.each do |file|
      # check yaml syntax
      begin
        parsed = YAML.load_file(file)
      rescue StandardError => err
        PuppetCheck.error_files.push("#{file}:\n#{err.to_s.gsub("(#{file}): ", '')}")
      else
        # perform some rudimentary hiera checks if data exists
        warnings = parsed.class.to_s == 'NilClass' ? [] : hiera(parsed)
        next PuppetCheck.warning_files.push("#{file}:\n#{warnings.join("\n")}") unless warnings.empty?
        PuppetCheck.clean_files.push(file.to_s)
      end
    end
  end

  # checks json (.json)
  def self.json(files)
    require 'json'

    files.each do |file|
      # check json syntax
      begin
        parsed = JSON.parse(File.read(file))
      rescue JSON::ParserError => err
        PuppetCheck.error_files.push("#{file}:\n#{err.to_s.lines.first.strip}")
      else
        warnings = []

        # check metadata.json
        if File.basename(file) == 'metadata.json'
          # metadata-json-lint has issues and is essentially no longer maintained, so here is an improved and leaner version of it
          require 'spdx-licenses'

          # check for errors
          errors = []

          # check for required keys
          %w(name version author license summary source dependencies).each do |key|
            errors.push("Required field '#{key}' not found.") unless parsed.key?(key)
          end

          # check for duplicate dependencies and requirements
          %w(requirements dependencies).each do |key|
            next unless parsed.key?(key)
            names = []
            parsed[key].each do |req_dep|
              name = req_dep['name']
              errors.push("Duplicate #{key} on #{name}.") if names.include?(name)
              names << name
            end
          end

          # check for deprecated fields
          %w(types checksum).each do |key|
            errors.push("Deprecated field '#{key}' found.") if parsed.key?(key)
          end

          # check for summary under 144 character
          errors.push('Summary exceeds 144 characters.') if parsed.key?('summary') && parsed['summary'].size > 144

          next PuppetCheck.error_files.push("#{file}:\n#{errors.join("\n")}") unless errors.empty?

          # check for warnings
          # check for operatingsystem_support
          warnings.push('Recommended field \'operatingsystem_support\' not found.') unless parsed.key?('operatingsystem_support')

          # check for spdx license (rubygems/util/licenses for rubygems >= 2.5 in the far future)
          if parsed.key?('license') && !SpdxLicenses.exist?(parsed['license']) && parsed['license'] !~ /[pP]roprietary/
            warnings.push("License identifier '#{parsed['license']}' is not in the SPDX list: http://spdx.org/licenses/")
          end
        # assume this is hieradata
        else
          # perform some rudimentary hiera checks if data exists
          warnings = hiera(parsed) unless parsed.class.to_s == 'NilClass'
        end
        next PuppetCheck.warning_files.push("#{file}:\n#{warnings.join("\n")}") unless warnings.empty?
        PuppetCheck.clean_files.push(file.to_s)
      end
    end
  end

  # checks hieradata
  def self.hiera(data)
    warnings = []
    data.each do |key, value|
      # check for nil values in the data (nil keys are fine)
      if (value.is_a?(Hash) && value.values.any?(&:nil?)) || (value.class.to_s == 'NilClass')
        warnings.push("Value(s) missing in key '#{key}'.")
      end
    end
    warnings
  end
end
