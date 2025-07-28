begin
  # temporarily supress warning messages for octocatalog-diff redefining puppet constants and then reactivate
  $VERBOSE = nil
  require 'octocatalog-diff'
  $VERBOSE = false

  # executes smoke and regression tests on catalogs
  class RegressionCheck
    # smoke testing
    def self.smoke(interface_nodes, octoconfig)
      options = config(octoconfig)
      nodes = options.key?(:node) ? [options[:node]] : interface_nodes
      nodes.each do |node|
        options[:node] = node
        OctocatalogDiff::API::V1.catalog(options)
      end
    end

    # regression testing
    # def self.regression(nodes, octoconfig)
    #   options = RegressionCheck.config(octoconfig)
    #   nodes.each { |node| stuff }
    # end

    # config file loading
    def self.config(octoconfig)
      private_class_method :method
      OctocatalogDiff::API::V1.config(filename: octoconfig)
    end
  end
rescue LoadError
  warn 'puppet-check: octocatalog-diff is not installed, and therefore the regression checks will be skipped'
  $VERBOSE = false
end
