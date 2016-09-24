### 1.4.0 (Roadmap)
- rudimentary catalog compilation testing? (only for Puppet4)
- minimum Puppet version increased from 3.4 to 3.7.
- rakefile interface with puppet-lint, rubocop, reek
- rspec puppet stubbing
- infrataster and analogous docker task like thing ripienaar did?
- add additional hiera checks

### 1.3.1 (Roadmap)
- split syntax and style checks to separate methods for speedup
- more args, fewer self accessors
- improved json and yaml output formats support (file arrays become file hashes and output results further handles formatting)
- metadata.json checks for dependency upper bounds, dependencies/operatingsystem_support as array of hashes, and operatingsystem and operatingsystem_release within operatingsystem_support

### 1.3.0 (Roadmap)
- Minimum Ruby version increased from 1.9.3 to 2.0.0.
- Minimum Puppet version increased from 3.2 to 3.4.
- Fixed issue where invalid arguments to PuppetLint were not displayed in error message.
- Support for outputting the results in YAML or JSON formats.
- Additional style check for `metadata.json`.
- Slight code cleanup and optimization.
- Block hieradata checks from excuting on `hiera.yaml`.
- do another reek and rubocop check
- some multithreading for speedup

### 1.2.1
- Code and output cleanup.
- Add arguments support to external module download methods.
- PuppetLint dependency version updated for 2.0 release.

### 1.2.0
- Support for external module dependencies with RSpecPuppet.
- Support for nested hash parsing in Hieradata checks.
- Support for `.puppet-lint.rc` config files in manually specified paths.
- A few bug fixes for RSpecPuppet support.

### 1.1.1 (yanked from rubygems.org)
- Rewrote and optimized RSpecPuppet module support.
- A variety of minor fixes, cleanup, and improvements (e.g. ignored files now outputs in cyan and not blue)

### 1.1.0
- Support for RSpec, RSpecPuppet, and Beaker.
- Empty hieradata file bug fix.

### 1.0.0
- Initial release.
