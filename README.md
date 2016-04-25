# Puppet Check

## Description
Puppet Check is a gem for comprehensive, efficient, streamlined, and easy verification and validation of your Puppet catalogs.

### Former Method for Catalog Checks
![Old](https://raw.githubusercontent.com/mschuchard/puppet-check/master/images/puppetcheck_old.png)

### Puppet Check Method for Catalog Checks
![New](https://raw.githubusercontent.com/mschuchard/puppet-check/master/images/puppetcheck_new.png)

### Why not Puppetlabs Spec Helper?
- Puppetlabs Spec Helper is a larger and varied gem with a different emphasis for its features.  Puppet Check is a lean and efficient gem solely for comprehensive Puppet catalog validation.
- Puppetlabs Spec Helper performs fewer types of checks.
- Puppetlabs Spec Helper has extra layers of gems in between it and the gems executing the checks.
- Puppetlabs Spec Helper does not enable interfacing through it to the gems executing the checks.
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
This will exist in the future release candidate.

### Optional Checks
`reek` checks will automatically be enabled for style checks if your Ruby version is `>= 2.1`. `rspec`, `rspec-puppet`, and `beaker` are other forthcoming optional checks.

## Contributing
Code should pass all spec tests. New features should involve new spec tests. Adherence to Rubocop and Reek is expected where not overly onerous or where the check is of dubious cost/benefit. While the version is currently tagged as `< 1.0.0`, please consult the `CHANGELOG` for the current development roadmap and contributing guidelines.
