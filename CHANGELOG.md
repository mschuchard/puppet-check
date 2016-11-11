### 1.4.0 (Roadmap)
- optional dep octocatalog-diff interface (minor)
- minimum Puppet version increased from 3.4 to 3.7 (minor)
- rakefile interface with puppet-lint, rubocop, reek (minor)
- rspec puppet stubbing (minor)
- acceptance testing with vagrant/docker+serverspec (minor)
- improved json and yaml output formats support (file arrays become file hashes and output results further handles formatting) (minor; this would be a big refactoring effort)
- split syntax and style checks to separate methods for style (patch)
- add additional hiera checks (patch)

### 1.3.1
- For the git and mercurial methods of downloading external module dependencies as spec fixtures, the module is now updated if it is already present and previously retrieved with git or mercurial respectively. Previously, a fresh clone was always attempted.
- Additional syntax and style checks within the `operatingsystem_support`, `requirements`, and `dependencies` hashes in `metadata.json`.
- Reek is now required dependency for all Ruby versions and locked to 3.11 for Ruby 2.0.
- Slight code cleanup and optimization.

### 1.3.0
- Minimum Ruby version increased from 1.9.3 to 2.0.0.
- Minimum Puppet version increased from 3.2 to 3.4.
- Fixed issue where invalid arguments to PuppetLint were not displayed in error message.
- Support for outputting the results in YAML or JSON formats.
- Additional style check for `metadata.json`.
- Slight code cleanup and optimization.
- Block hieradata checks from executing on `hiera.yaml`.

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
