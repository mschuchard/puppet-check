require_relative '../puppet-check'

# executes diagnostics on data files
class DataParser
  # checks yaml syntax (.yaml or .yml)
  def self.yaml(files)
    require 'yaml'

    files.each do |file|
      # check yaml syntax
      begin
        parsed = YAML.load_file(file)
      rescue StandardError => err
        PuppetCheck.error_files.push("-- #{file}:\n#{err.to_s.gsub("(#{file}): ", '')}")
      else
        warnings = hiera(parsed)
        return PuppetCheck.warning_files.push("-- #{file}:\n#{warnings.join("\n")}") unless warnings.empty?
        PuppetCheck.clean_files.push("-- #{file}")
      end
    end
  end

  # checks json syntax (.json)
  def self.json(files)
    require 'json'

    files.each do |file|
      # check json syntax
      begin
        parsed = JSON.parse(File.read(file))
      rescue JSON::ParserError => err
        PuppetCheck.error_files.push("-- #{file}:\n#{err.to_s.lines.first.strip}")
      else
        # check metadata.json
        if file =~ /.*metadata\.json$/
          require 'spdx-licenses'

          # metadata-json-lint has issues and is essentially no longer maintained so here is an improved and leaner version of it
          # check for errors
          errors = []

          # check for required keys
          %w(name version author license summary source dependencies).each do |key|
            errors.push("Required field '#{key}' not found in metadata.json.") unless parsed.key?(key)
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

          return PuppetCheck.error_files.push("-- #{file}:\n#{errors.join("\n")}") unless errors.empty?

          # check for warnings
          warnings = []

          # check for spdx license
          if parsed.key?('license') && !SpdxLicenses.exist?(parsed['license']) && parsed['license'] != 'proprietary'
            warnings.push("License identifier '#{parsed['license']}' is not in the SPDX list: http://spdx.org/licenses/")
          end

          return PuppetCheck.warning_files.push("-- #{file}:\n#{warnings.join("\n")}") unless warnings.empty?
        else
          # check for questionable hieradata
          warnings = hiera(parsed)
          return PuppetCheck.warning_files.push("-- #{file}:\n#{warnings.join("\n")}") unless warnings.empty?
        end
        PuppetCheck.clean_files.push("-- #{file}")
      end
    end
  end

  # checks hieradata
  def self.hiera(data)
    warnings = []
    data.each do |key, value|
      warnings.push("Values missing in key '#{key}'.") if value.nil?
    end
    warnings
  end
end
