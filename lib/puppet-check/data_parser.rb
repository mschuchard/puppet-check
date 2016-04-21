require_relative '../puppet-check'

# executes diagnostics on data files
class DataParser
  # checks yaml syntax (.yaml or .yml)
  def self.yaml(file)
    require 'yaml'
    # check yaml syntax
    begin
      YAML.load_file(file)
    rescue StandardError => err
      PuppetCheck.error_files.push("-- #{err}")
    else
      PuppetCheck.clean_files.push("-- #{file}")
    end
  end

  # checks json syntax (.json)
  # TODO: RC more checks if metadata.json
  def self.json(file)
    require 'json'
    require 'metadata-json-lint/rake_task'
    # check json syntax
    begin
      JSON.parse(File.read(file))
    # TODO: RC error info kind of sucks
    rescue JSON::ParserError => err
      PuppetCheck.error_files.push("-- #{file}: #{err.to_s.lines.first}")
    else
      # Rake::Task[:metadata_lint].invoke
      PuppetCheck.clean_files.push("-- #{file}")
    end
  end
end
