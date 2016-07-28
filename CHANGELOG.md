### 1.3.0 (Roadmap)
- Minimum Ruby version increased from 1.9.3 to 2.0.0.
- Minimum Puppet version increased from 3.2 to 3.4.
- rakefile interface with puppet-lint, rubocop, reek
- json and yaml output formats support (error_files becomes hash with file keys and array of issues; refactor output_results)
- rudimentary catalog compilation testing?
- rspec puppet stubbing
- infrataster and analogous docker task like thing ripienaar did?
- add additional hiera checks

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
