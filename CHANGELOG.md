### 1.4.0 (Roadmap)
- improved json and yaml output formats support (file arrays become file hashes and output results further handles formatting)

### 1.3.1 (Roadmap)
- split syntax and style checks to separate methods for speedup
- more args, fewer self accessors

### 1.3.0 (Roadmap)
- Minimum Ruby version increased from 1.9.3 to 2.0.0.
- Minimum Puppet version increased from 3.2 to 3.4.
- Fixed issue where invalid arguments to PuppetLint were not displayed in error message.
- Support for outputting the results in YAML or JSON formats.
- rakefile interface with puppet-lint, rubocop, reek
- rudimentary catalog compilation testing?
- rspec puppet stubbing
- infrataster and analogous docker task like thing ripienaar did?
- add additional hiera checks
- due to a bug in recently updated ruby/rspec/other, the system checks are suddenly behaving extremely erratically; look into this
- refactor output results
- pretty up yaml output
- check format validity of yaml and json output

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
