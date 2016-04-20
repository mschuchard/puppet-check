require_relative '../puppet-check'

# executes diagnostics on data files
class PuppetCheck::DataParser
  # checks yaml syntax (.yaml or .yml)
  def self.yaml(file)
    require 'yaml'
    # check yaml syntax
    begin
      YAML.load_file(file)
    rescue StandardError => err
      PuppetCheck.error_files.push("-- #{err}")
      return
    end
    PuppetCheck.clean_files.push("-- #{file}")
  end

  # checks json syntax (.json)
  # TODO: RC more checks if metadata.json
  def self.json(file)
    require 'json'
    # require 'metadata-json-lint/rake_task'
    # check json syntax
    begin
      JSON.parse(File.read(file))
    rescue JSON::ParserError => err
      PuppetCheck.error_files.push("-- #{file}: #{err.to_s.lines.first}")
      return
    end
    # Rake::Task[:metadata_lint].invoke
    PuppetCheck.clean_files.push("-- #{file}")
  end
end
