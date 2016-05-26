### 1.3.0 (Roadmap)
- minimum puppet version bump to 3.5 and future parser enabled by force for version < 4 (search code on 'future')
- minimum ruby version bump to 2.0.0 (switch vagrant to centos7, remove 1.9.3 from travis.yml, add 2.3.x to travis.yml, update readme, remove psych::syntaxerror from dataparser.yaml, and remove 1.9.3 test from rubyparser.template style spec)

### 1.2.0 (Roadmap)
- json and yaml output formats support (error_files becomes hash with file keys and array of issues; refactor output_results)
- rspec-puppet external dependencies support
- add additional hiera checks, including nested hash parsing
- explore puppet-catalog-test integration

### 1.1.1 (Roadmap)
- refactor and cleanup
- redo rspec_puppet_setup as cleaner/lighter rspec::puppet::setup

### 1.1.0
- Support for RSpec, RSpec-Puppet, and Beaker.
- Empty hieradata file bug fix.

### 1.0.0
- Initial release.
