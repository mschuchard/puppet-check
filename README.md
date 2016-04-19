# Puppet Check

## Description
Puppet Check is a gem for comprehensive, efficient, streamlined, and easy verification and validation of your Puppet catalogs.

### Former Method for Catalog Checks
![Old](https://raw.githubusercontent.com/mschuchard/puppet-check/master/puppetcheck_old.png)

### Puppet Check Method for Catalog Checks
![New](https://raw.githubusercontent.com/mschuchard/puppet-check/master/puppetcheck_new.png)

### Why not Puppetlabs Spec Helper?
- Puppetlabs Spec Helper is a larger and varied gem with a different emphasis for its features.  Puppet Check is a lean and efficient gem solely for comprehensive Puppet catalog validation.
- Puppetlabs Spec Helper performs fewer types of checks.
- Puppetlabs Spec Helper has extra layers of gems in between it and the gems executing the checks.
- Puppetlabs Spec Helper does not enable interfacing through it to the gems executing the checks.
- Puppetlabs Spec Helper has no CLI.

## Usage
Puppet Check requires `ruby` >= 1.9.3, `puppet` >= 3.2, and `puppet-lint` >= 1.1.0. All other dependencies should be fine with various versions. Puppet Check can be used either with a CLI or Rake tasks.

### CLI
This will exist in the future beta.

### Rake
This will exist in the future release candidate.

### Optional Checks
`reek` checks will automatically be enabled for style checks if your Ruby version is >= 2.1. `rspec`, `rspec-puppet`, and `beaker` are other forthcoming optional checks.

### Contributing

Code should pass all spec tests. New features should involve new spec tests. Adherence to Rubocop and Reek is expected where not overly onerous or where the check is of dubious cost/benefit.

## Notes
While the version is currently tagged as < 1.0.0, please consult the CHANGELOG for the current development roadmap and contributing guidelines.
