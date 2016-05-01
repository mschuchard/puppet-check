# Puppet Check

## Description
Puppet Check is a gem for comprehensive, efficient, streamlined, and easy verification and validation of your Puppet catalogs.

### Former Method for Catalog Checks
![Old](https://raw.githubusercontent.com/mschuchard/puppet-check/master/images/puppetcheck_old.png)

### Puppet Check Method for Catalog Checks
![New](https://raw.githubusercontent.com/mschuchard/puppet-check/master/images/puppetcheck_new.png)

### Example Output

```
The following files have errors:
-- puppet_catalog/manifests/syntax.pp: This Variable has no effect. A value was produced and then forgotten (one or more preceding expressions may have the wrong form) at 1:1
Illegal variable name, The given name '' does not conform to the naming rule /^((::)?[a-z]\w*)*((::)?[a-z_]\w*)$/ at 1:1
Found 2 errors. Giving up
-- puppet_catalog/templates/syntax.epp: This Name has no effect. A value was produced and then forgotten (one or more preceding expressions may have the wrong form) at 2:4
-- puppet_catalog/lib/syntax.rb: (eval):1: syntax error, unexpected =>, expecting end-of-input
BEGIN {throw :good}; i => am : a '' ruby.file { with } &bad syntax
                         ^
-- puppet_catalog/templates/syntax.erb: (erb):1: syntax error, unexpected tIDENTIFIER, expecting ')'
... am "; _erbout.concat(( @a ruby ).to_s); _erbout.concat " te...
...                               ^
-- (puppet_catalog/hieradata/syntax.yaml): block sequence entries are not allowed in this context at line 1 column 4
-- puppet_catalog/hieradata/syntax.json: 757: unexpected token at '{
-- puppet_catalog/metadata_syntax/metadata.json: Required field 'version' not found in metadata.json.
Duplicate dependencies on puppetlabs/nothing.
Deprecated field 'checksum' found.
Summary exceeds 144 characters.
-- puppet_catalog/librarian_syntax/Puppetfile: (eval):3: syntax error, unexpected ':', expecting end-of-input
    librarian: 'puppet'
              ^
The following files have warnings:
-- puppet_catalog/manifests/style.pp: double quoted string containing no variables at line 2, column 8
indentation of => is not properly aligned at line 2, column 5
-- puppet_catalog/lib/style.rb: 1:1: W: Useless assignment to variable - `hash`.
1:10: C: Use the new Ruby 1.9 hash syntax.
2:1: C: Do not introduce global variables.
3:6: C: Prefer single-quoted strings when you don't need string interpolation or special symbols.
[7]:Attribute: Issue#foobarbaz is a writable attribute [https://github.com/troessner/reek/blob/master/docs/Attribute.md]
-- puppet_catalog/hieradata/style.yaml: Values missing in key 'value'.
-- puppet_catalog/metadata_style/metadata.json: License identifier Imaginary is not in the SPDX list: http://spdx.org/licenses/
-- puppet_catalog/librarian_style/Puppetfile: 2:3: C: Align the parameters of a method call if they span more than one line.
5:13: C: Use the new Ruby 1.9 hash syntax.
The following files have no errors or warnings:
-- puppet_catalog/manifests/good.pp
-- puppet_catalog/templates/good.epp
-- puppet_catalog/lib/good.rb
-- puppet_catalog/templates/style.erb
-- puppet_catalog/templates/good.erb
-- puppet_catalog/hieradata/good.yaml
-- puppet_catalog/hieradata/good.json
-- puppet_catalog/metadata_good/metadata.json
-- puppet_catalog/librarian_good/Puppetfile
The following files were unrecognized formats and therefore not processed:
-- puppet_catalog/foobarbaz
```

### Why not Puppetlabs Spec Helper?
- Puppetlabs Spec Helper is a larger and varied gem with a different emphasis for its features.  Puppet Check is a lean and efficient gem solely for comprehensive Puppet catalog validation.
- Puppetlabs Spec Helper performs fewer types of checks.
- Puppetlabs Spec Helper has extra layers of gems in between it and the gems executing the checks.
- Puppetlabs Spec Helper does not allow interfacing through it to the gems executing the checks.
- Puppetlabs Spec Helper has no CLI.

## Usage
Puppet Check requires `ruby >= 1.9.3`, `puppet >= 3.2`, and `puppet-lint >= 1.1.0`. All other dependencies should be fine with various versions. Puppet Check can be used either with a CLI or Rake tasks.

### CLI
```
usage: puppet-check [options] paths
    -f, --future                     Enable future parser
    -s, --style                      Enable style checks
        --puppet-lint arg_one,arg_two
                                     Arguments for PuppetLint ignored checks
        --rubocop arg_one,arg_two    Arguments for Rubocop disabled cops
```
The command line interface enables the ability to select the Puppet future parser, additional style checks besides the syntax checks, and to specify PuppetLint and Rubocop checks to ignore. It should be noted that your `.puppet-lint.rc`, `.rubocop.yml`, and `*.reek` files should still be automatically respected by the individual style checkers if you prefer those to a simplified CLI.
```
Example:
puppet-check -s --puppet-lint no-hard_tabs-check,no-80chars-check --rubocop Metrics/LineLength,Style/Encoding path/to/puppet_catalog
```

### Rake
Interfacing with Puppet-Check via `rake` requires a `require puppet-check/tasks` in your Rakefile. This generates two `rake` commands:
```
rake puppetcheck:all       # Execute Puppet-Check syntax and style checks
rake puppetcheck:syntax    # Execute Puppet-Check syntax checks
```
The style checks from within `rake` are directly interfaced to `puppet-lint`, `rubocop`, and `reek`. This means that all arguments and options should be specified from within your `.puppet-lint.rc`, `.rubocop.yml`, and `*.reek`. The capability to pass arguments and options to them from within the `Rakefile` will be considered for future versions.

### Optional Checks
`reek` checks will automatically be enabled for style checks if your Ruby version is `>= 2.1`. `rspec`, `rspec-puppet`, and `beaker` are other forthcoming optional checks.

## Contributing
Code should pass all spec tests. New features should involve new spec tests. Adherence to Rubocop and Reek is expected where not overly onerous or where the check is of dubious cost/benefit. While the version is currently tagged as `< 1.0.0`, please consult the `CHANGELOG` for the current development roadmap and contributing guidelines.
