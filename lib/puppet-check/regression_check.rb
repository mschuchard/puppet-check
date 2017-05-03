require 'octocatalog-diff'

# executes smoke and regression tests on catalogs
class RegressionCheck
  # smoke testing
  def self.smoke(interface_nodes, octoconfig)
    options = RegressionCheck.config(octoconfig)
    # TODO: add return code and catch upward
    nodes = options.key?(:node) ? [options[:node]] : interface_nodes
    nodes.each do |node|
      options[:node] = node
      OctocatalogDiff::API::V1.catalog(options)
    end

    # https://github.com/github/octocatalog-diff/blob/master/doc/dev/api/v1/calls/catalog.md
    # https://github.com/github/octocatalog-diff/blob/master/examples/api/v1/catalog-builder-local-files.rb
  end

  # regression testing
  # def self.regression(nodes, octoconfig)
    # options = RegressionCheck.config(octoconfig)
    # nodes.each { |node| stuff }
  # end

  # config file loading; # TODO: this needs to run only once per PuppetCheck execution
  def self.config(octoconfig)
    # TODO: logger and test options
    OctocatalogDiff::API::V1.config(filename: octoconfig)

    # https://github.com/github/octocatalog-diff/blob/master/doc/dev/api/v1/calls/config.md
    # https://github.com/github/octocatalog-diff/blob/master/doc/configuration.md
  end
end
