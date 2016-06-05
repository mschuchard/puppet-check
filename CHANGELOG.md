### 1.4.0 (Roadmap)
- minimum puppet version bump to 3.5 and future parser enabled by force for version < 4 (search code on 'future')

### 1.3.0 (Roadmap)
- minimum ruby version bump to 2.0.0 (switch vagrant to centos7, remove 1.9.3 from travis.yml, add 2.3.x to travis.yml, update readme, remove psych::syntaxerror from dataparser.yaml, and remove 1.9.3 test from rubyparser.template style spec)
- rakefile interface with puppet-lint, rubocop, reek
- direct interface to rubocop and reek in rubyparser
- json and yaml output formats support (error_files becomes hash with file keys and array of issues; refactor output_results)

### 1.2.1 (Roadmap)
- move rspec_puppet support to separate class
- improve rspec_puppet_git and rspec_puppet_forge (check librarian puppet, git man, forge docs for ideas)
- add rspec_puppet_hg

### 1.2.0 (Roadmap)
- Support for external module dependencies with RSpecPuppet.
- add additional hiera checks, including nested hash parsing
- rudimentary catalog compilation testing
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
