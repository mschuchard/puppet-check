require_relative '../puppet_check'

# executes diagnostics on data files
class DataParser
  # checks yaml (.yaml/.yml)
  def self.yaml(files)
    require 'yaml'

    files.each do |file|
      # check yaml syntax
      parsed = YAML.load_file(file)
    rescue StandardError => err
      PuppetCheck.settings[:error_files].push("#{file}:\n#{err.to_s.gsub("(#{file}): ", '')}")
    else
      warnings = []

      # perform some rudimentary hiera checks if data exists and is hieradata
      warnings = hiera(parsed, file) if parsed && (File.basename(file) != 'hiera.yaml')

      next PuppetCheck.settings[:warning_files].push("#{file}:\n#{warnings.join("\n")}") unless warnings.empty?
      PuppetCheck.settings[:clean_files].push(file.to_s)
    end
  end

  # checks eyaml (.eyaml/.eyml)
  def self.eyaml(files, public, private)
    require 'openssl'

    # keys specified?
    if public.nil? || private.nil?
      PuppetCheck.settings[:ignored_files].concat(files)
      return warn 'Public X509 and/or Private RSA PKCS7 certs were not specified. EYAML checks will not be executed.'
    end

    # keys exist?
    unless File.file?(public) && File.file?(private)
      PuppetCheck.settings[:ignored_files].concat(files)
      return warn 'Specified Public X509 and/or Private RSA PKCS7 certs do not exist. EYAML checks will not be executed.'
    end

    # setup decryption
    rsa = OpenSSL::PKey::RSA.new(File.read(private))
    x509 = OpenSSL::X509::Certificate.new(File.read(public))

    files.each do |file|
      # grab all encoded portions of the eyaml

      # decrypt the encoded portions
      decrypted = OpenSSL::PKCS7.new(File.read(file)).decrypt(rsa, x509)

      # insert decrypted portions back into eyaml (pass into loader below)

      # check yaml syntax
      begin
        parsed = YAML.load_file(decrypted)
      rescue StandardError => err
        PuppetCheck.settings[:error_files].push("#{file}:\n#{err.to_s.gsub("(#{file}): ", '')}")
      else
        warnings = []

        # perform some rudimentary hiera checks if data exists and is hieradata
        warnings = hiera(parsed, file) if parsed

        next PuppetCheck.settings[:warning_files].push("#{file}:\n#{warnings.join("\n")}") unless warnings.empty?
        PuppetCheck.settings[:clean_files].push(file.to_s)
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
        PuppetCheck.settings[:error_files].push("#{file}:\n#{err.to_s.lines.first.strip}")
      else
        warnings = []

        # check metadata.json
        if File.basename(file) == 'metadata.json'
          # metadata-json-lint has issues and is essentially no longer maintained, so here is an improved and leaner version of it
          require 'rubygems/util/licenses'

          # check for errors
          errors = []

          # check for required keys
          %w[name version author license summary source dependencies].each do |key|
            errors.push("Required field '#{key}' not found.") unless parsed.key?(key)
          end

          # check requirements and dependencies keys
          %w[requirements dependencies].each do |key|
            # skip if key is missing or value is an empty string, array, or hash
            next if !parsed.key?(key) || parsed[key].empty?

            # check that dependencies and requirements are an array of hashes
            next errors.push("Field '#{key}' is not an array of hashes.") unless (parsed[key].is_a? Array) && (parsed[key][0].is_a? Hash)

            # check dependencies and requirements values
            names = []
            parsed[key].each do |req_dep|
              # check for duplicate dependencies and requirements
              name = req_dep['name']
              next errors.push("Duplicate #{key} on #{name}.") if names.include?(name)
              names << name

              # warn and skip if key is missing
              next warnings.push("'#{req_dep['name']}' is missing a 'version_requirement' key.") if req_dep['version_requirement'].nil?

              # warn and skip if no upper bound
              next warnings.push("'#{req_dep['name']}' is missing an upper bound.") unless req_dep['version_requirement'].include?('<')

              # check for semantic versioning
              if key == 'dependencies' && req_dep['version_requirement'] !~ /\d+\.\d+\.\d+.*\d+\.\d+\.\d+/
                warnings.push("'#{req_dep['name']}' has non-semantic versioning in its 'version_requirement' key.")
              end
            end
          end

          # check for deprecated fields
          %w[types checksum].each do |key|
            errors.push("Deprecated field '#{key}' found.") if parsed.key?(key)
          end

          # check for summary under 144 character
          errors.push('Summary exceeds 144 characters.') if parsed.key?('summary') && parsed['summary'].size > 144

          next PuppetCheck.settings[:error_files].push("#{file}:\n#{errors.join("\n")}") unless errors.empty?

          # check for warnings
          # check for operatingsystem_support hash array
          if parsed.key?('operatingsystem_support')
            # check if operatingsystem_support array is actually empty
            if !(parsed['operatingsystem_support'].is_a? Array) || parsed['operatingsystem_support'].empty? || (!parsed['operatingsystem_support'].empty? && !(parsed['operatingsystem_support'][0].is_a? Hash))
              warnings.push('Recommended field \'operatingsystem\' not found.')
              warnings.push('Recommended field \'operatingsystemrelease\' not found.')
            else
              # check for operatingsystem string
              if parsed['operatingsystem_support'][0].key?('operatingsystem')
                warnings.push('Field \'operatingsystem\' is not a string.') unless parsed['operatingsystem_support'][0]['operatingsystem'].is_a? String
              else
                warnings.push('Recommended field \'operatingsystem\' not found.')
              end

              # check for operatingsystemrelease string array
              if parsed['operatingsystem_support'][0].key?('operatingsystemrelease')
                warnings.push('Field \'operatingsystemrelease\' is not a string array.') unless parsed['operatingsystem_support'][0]['operatingsystemrelease'][0].is_a? String
              else
                warnings.push('Recommended field \'operatingsystemrelease\' not found.')
              end
            end
          else
            warnings.push('Recommended field \'operatingsystem_support\' not found.')
          end

          # check for spdx license
          if parsed.key?('license') && !Gem::Licenses.match?(parsed['license']) && parsed['license'] !~ /[pP]roprietary/
            warnings.push("License identifier '#{parsed['license']}' is not in the SPDX list: http://spdx.org/licenses/")
          end
        # assume this is task metadata if it has this key
        elsif parsed.key?('description')
          # check that description is a string
          warnings.push('description value is not a String') unless parsed['description'].is_a?(String)
          # check that input_method is one of three possible values
          if parsed.key?('input_method')
            if parsed['input_method'].is_a?(String)
              warnings.push('input_method value is not one of environment, stdin, or powershell') unless %w[environment stdin powershell].include?(parsed['input_method'])
            else
              warnings.push('input_method value is not a String')
            end
          end
          # check that parameters is a hash
          if parsed.key?('parameters') && !parsed['parameters'].is_a?(Hash)
            warnings.push('parameters value is not a Hash')
          end
          # check that puppet_task_version is an integer
          if parsed.key?('puppet_task_version') && !parsed['puppet_task_version'].is_a?(Integer)
            warnings.push('puppet_task_version value is not an Integer')
          end
          # check that supports_noop is a boolean
          if parsed.key?('supports_noop') && !(parsed['supports_noop'].is_a?(TrueClass) || parsed['supports_noop'].is_a?(FalseClass))
            warnings.push('supports_noop value is not a Boolean')
          end
        # assume this is hieradata and ensure it is non-empty
        elsif parsed
          # perform some rudimentary hiera checks if data exists
          warnings = hiera(parsed, file)
        end
        next PuppetCheck.settings[:warning_files].push("#{file}:\n#{warnings.join("\n")}") unless warnings.empty?
        PuppetCheck.settings[:clean_files].push(file.to_s)
      end
    end
  end

  # checks hieradata
  def self.hiera(data, file)
    private_class_method :method
    warnings = []

    # disregard nil/undef value data check if default values (common)
    unless /^common/.match?(file)
      data.each do |key, value|
        # check for nil values in the data (nil keys are fine)
        if (value.is_a?(Hash) && value.values.any?(&:nil?)) || value.nil?
          warnings.push("Value(s) missing in key '#{key}'.")
        end
      end
    end

    # check that '---' does not show up more than once in the hieradata
    warnings.push('The string --- appears more than once in this data and Hiera may fail to parse it correctly.') if File.read(file).scan(/---/).count >= 2

    warnings
  end
end
