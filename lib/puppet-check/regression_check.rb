require 'octocatalog-diff'

# executes compilation and regression tests on catalogs
class RegressionCheck
  # compilation testing
  def self.compile(nodes, octoconfig)
    options = RegressionCheck.config(octoconfig)
    # TODO: add return code and catch upward; add nodes arg upward
    nodes.each { |node| OctocatalogDiff::API::V1.catalog(node: node) }

    # https://github.com/github/octocatalog-diff/blob/master/doc/dev/api/v1/calls/catalog.md
    # https://github.com/github/octocatalog-diff/blob/master/examples/api/v1/catalog-builder-local-files.rb
  end

  # regression testing
  def self.regression
    options = RegressionCheck.config
    #
  end

  # config file loading
  def self.config(octoconfig)
    # TODO: logger and test options
    OctocatalogDiff::API::V1.config(filename: octoconfig)

    # https://github.com/github/octocatalog-diff/blob/master/doc/dev/api/v1/calls/config.md
    # https://github.com/github/octocatalog-diff/blob/master/doc/configuration.md
  end
end
