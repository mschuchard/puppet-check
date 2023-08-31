# Puppet Check
[![CircleCI](https://circleci.com/gh/mschuchard/puppet-check.svg?style=svg)](https://circleci.com/gh/mschuchard/puppet-check)

- [Description](#description)
- [Usage](#usage)
  - [CLI](#cli)
  - [Rake](#rake)
  - [API](#api)
  - [Docker](#docker)
  - [Vagrant](#vagrant)
  - [Exit Codes](#exit-codes)
  - [Optional Dependencies](#optional-dependencies)
- [Contributing](#contributing)

## Description
Puppet Check is a gem that provides a comprehensive, streamlined, and efficient analysis of the syntax, style, and validity of your entire Puppet code and data.

**IMPORTANT**: The current support for encrypted yaml validation is experimental. The code is blocked in the current release (the files will continue to be treated as unrecognized) and will be unblocked when the feature is finished in a future version.

### Former Method for Code and Data Checks
![Old](https://raw.githubusercontent.com/mschuchard/puppet-check/master/images/puppetcheck_old.png)

### Puppet Check Method for Code and Data Checks
![New](https://raw.githubusercontent.com/mschuchard/puppet-check/master/images/puppetcheck_new.png)

### Example Output
```
The following files have errors:
-- manifests/syntax.pp:
This Variable has no effect. A value was produced and then forgotten (one or more preceding expressions may have the wrong form) at 1:1
Illegal variable name, The given name '' does not conform to the naming rule /^((::)?[a-z]\w*)*((::)?[a-z_]\w*)$/ at 1:1
Found 2 errors. Giving up

-- templates/syntax.epp:
This Name has no effect. A value was produced and then forgotten (one or more preceding expressions may have the wrong form) at 2:4

-- lib/syntax.rb:
(eval):1: syntax error, unexpected =>, expecting end-of-input
BEGIN {throw :good}; i => am : a '' ruby.file { with } &bad syntax
                         ^

-- templates/syntax.erb:
(erb):1: syntax error, unexpected tIDENTIFIER, expecting ')'
... am "; _erbout.concat(( @a ruby ).to_s); _erbout.concat " te...
...                               ^

-- hieradata/syntax.yaml:
block sequence entries are not allowed in this context at line 2 column 4

-- hieradata/syntax.json:
743: unexpected token at '{

-- metadata_syntax/metadata.json:
Required field 'version' not found.
Field 'requirements' is not an array of hashes.
Duplicate dependencies on puppetlabs/nothing.
Deprecated field 'checksum' found.
Summary exceeds 144 characters.

-- librarian_syntax/Puppetfile:
(eval):3: syntax error, unexpected ':', expecting end-of-input
    librarian: 'puppet'
              ^

The following files have warnings:
-- manifests/style_lint.pp:
2:8: double quoted string containing no variables
2:5: indentation of => is not properly aligned (expected in column 8, but found it in column 5)

-- manifests/style_parser.pp:
Unrecognized escape sequence '\[' at 2:77
Unrecognized escape sequence '\]' at 2:77
2:45: double quoted string containing no variables

-- lib/style.rb:
1:1: W: Useless assignment to variable - `hash`.
1:10: C: Use the new Ruby 1.9 hash syntax.
2:1: C: Do not introduce global variables.
3:6: C: Prefer single-quoted strings when you don't need string interpolation or special symbols.
[7]:Attribute: Issue#foobarbaz is a writable attribute [https://github.com/troessner/reek/blob/master/docs/Attribute.md]
[6]:IrresponsibleModule: Issue has no descriptive comment [https://github.com/troessner/reek/blob/master/docs/Irresponsible-Module.md]

-- templates/style.erb:
3: already initialized constant TEMPLATE
2: previous definition of TEMPLATE was here

-- hieradata/style.yaml:
Value(s) missing in key 'value'.
Value(s) missing in key 'and'.
The string --- appears more than once in this data and Hiera will fail to parse it correctly.

-- metadata_style/metadata.json:
Recommended field 'operatingsystem_support' not found.
'pe' is missing an upper bound.
License identifier 'Imaginary' is not in the SPDX list: http://spdx.org/licenses/

-- metadata_style_two/metadata.json:
Recommended field 'operatingsystem' not found.
Recommended field 'operatingsystemrelease' not found.
'puppetlabs/one' has non-semantic versioning in its 'version_requirement' key.
'puppetlabs/two' is missing an upper bound.

-- librarian_style/Puppetfile:
2:3: C: Align the parameters of a method call if they span more than one line.
5:13: C: Use the new Ruby 1.9 hash syntax.

The following files have no errors or warnings:
-- manifests/good.pp
-- templates/good.epp
-- spec/facter/facter_spec.rb
-- lib/good.rb
-- templates/no_method_error.erb
-- templates/good.erb
-- hieradata/good.yaml
-- metadata.json
-- hieradata/good.json
-- metadata_good/metadata.json
-- librarian_good/Puppetfile

The following files have unrecognized formats and therefore were not processed:
-- foobarbaz
```

### What About Puppet Development Kit?
The fairly recent release of the Puppet Development Kit (PDK) will hopefully eventually bring about the capability to test and validate your Puppet code and data in a streamlined, efficient, comprehensive, and accurate fashion comparable to Puppet Check. Unfortunately, the PDK has not yet achieved feature or efficiency parity with Puppet Check. The goal is for the PDK to one day replace Puppet Check and for Puppet Check to enter maintenance mode, but for now Puppet Check is still needed to lead Puppet testing.

### What About PDK now?
As of version 2.4.0 of the PDK, the PDK has essentially more or less achieved feature parity with Puppet Check. Although the PDK is not as efficient (including especially that Puppet Check executes significantly faster), it is still supported by Puppetlabs. Therefore, if you need an efficient and comprehensive Puppet validation solution, then you can still utilize Puppet Check, but the PDK is a recommended alternative for the future.

## Usage
Please see the [Gemspec](puppet-check.gemspec) for dependency information.  All other dependencies should be fine with various versions. Puppet Check can be used with a CLI, Rake tasks, or API, from your system, rbenv, rvm, Docker, or Vagrant. Please note all interfaces (API by default, but can be modified) will ignore any directories named `fixtures`, or specified paths with that directory during file checks and spec tests.

### CLI
```
usage: puppet-check [options] paths
        --version                    Display the current version.
        --fail-on-warnings           Fail on warnings
    -s, --style                      Enable style checks
        --smoke                      Enable smoke testing
    -r, --regression                 Enable regression testing (in progress, do not use)
        --public cert.pem            Public key for EYAML checks
        --private cert.pem           Private key for EYAML checks
    -o, --output format              Format for results output (default is text): text, json, or yaml
        --octoconfig config_file     Octocatalog-diff configuration file to use
    -n node1.example.com,node2.example.com,
        --octonodes                  Octocatalog-diff nodes to test catalog on
        --puppet-lint arg_one,arg_two
                                     Arguments for PuppetLint ignored checks
    -c, --config file                Load PuppetLint options from file
        --rubocop arg_one,arg_two    Arguments for Rubocop disabled cops
```

The command line interface enables the ability to select additional style checks besides the syntax checks, and to specify PuppetLint and Rubocop checks to ignore. If you require a more robust interface to PuppetLint, Rubocop, and Reek, then please use `.puppet-lint.rc`, `.rubocop.yml` and `*.reek` config files. The `.puppet-lint.rc` can be specified with the `-c` argument. If it is not specified, then PuppetLint will automatically load one from `.puppet-lint.rc`, `~/.puppet-lint.rc`, or `/etc/puppet-lint.rc`, in that order of preference. The nearest `.rubocop.yml` and `*.reek` will be automatically respected.

Example:
```
puppet-check -s --puppet-lint no-hard_tabs-check,no-140chars-check --rubocop Metrics/LineLength,Style/Encoding -o yaml path/to/code_and_data
```

### Rake
Interfacing with Puppet-Check via `rake` requires a `require puppet-check/tasks` in your Rakefile. This generates the following `rake` commands:

```
rake puppetcheck           # Execute all Puppet-Check checks
rake puppetcheck:file      # Execute Puppet-Check file checks
rake puppetcheck:spec      # Execute RSpec and RSpec-Puppet tests
rake puppetcheck:beaker    # Execute Beaker acceptance tests
rake puppetcheck:kitchen:* # Execute Test Kitchen acceptance tests
```

#### puppetcheck:file
You can add style, smoke, and regression checks to the `rake puppetcheck:file`, or change the output format, by adding the following after the require:

```ruby
# example of modifying Puppet Check behavior and creating a custom task
settings = {}
settings[:fail_on_warnings] = true # default false
settings[:style] = true # default false
settings[:smoke] = true # default false
settings[:regression] = true # in progress, do not use; default false
settings[:public] = 'public.pem' # default nil
settings[:private] = 'private.pem' # default nil
settings[:output_format] = 'yaml' # also 'json'; default 'text'
settings[:octoconfig] = '$HOME/octocatalog-diff.cfg.rb' # default '.octocatalog-diff.cfg.rb'
settings[:octonodes] = %w(server.example.com) # default: %w(localhost.localdomain)
settings[:puppetlint_args] = ['--puppetlint-arg-one', '--puppetlint-arg-two'] # default []
settings[:rubocop_args] = ['--except', 'rubocop-arg-one,rubocop-arg-two'] # default []

desc 'Execute custom Puppet-Check file checks'
task :file_custom do
  Rake::Task[:'puppetcheck:file'].invoke(settings)
end
```

Please note that `rspec` does not support yaml output and therefore would still use the default 'progress' formatter even if `yaml` is specified as the format option to Puppet Check.

The style checks from within `rake puppetcheck:file` are directly interfaced to `puppet-lint`, `rubocop`, and `reek`. This means that all arguments and options should be specified from within your `.puppet-lint.rc`, `.rubocop.yml`, and `*.reek`. However, you can alternatively utilize the hashes listed above.

#### puppetcheck:spec
The spec tests will be executed against everything that matches the pattern `**/{classes, defines, facter, functions, hosts, puppet, unit, types}/**/*_spec.rb`. Any of these directories inside of a `fixtures` directory will be ignored. This means everything in the current path that appears to be a Puppet module spec test for your module (not dependencies) will be regarded as such and executed during this rake task.

Please note it is perfectly acceptable to only execute standard RSpec tests in your modules and not use the extended RSpec Puppet matchers. If no Puppet module directories are identified during directory parsing, then no RSpec Puppet related actions (including those described below) will be performed.

Prior to executing the spec tests, Puppet Check will parse everything in the current path and identify all `spec` directories not within `fixtures` directories. It will then execute RSpec Puppet setup actions inside all directories one level above that contain a `manifests` directory. This is assumed to be a Puppet module directory. These setup actions include creating all of the necessary directories inside of `spec/fixtures`, creating a blank `site.pp` if it is missing, symlinking everything from the module that is needed into fixtures (automatically replaces functionality of self module symlink in `.fixtures.yaml` from Puppetlabs Spec Helper), and creates the `spec_helper.rb` if it is missing. Note these setup actions can replace `rspec-puppet-init` from RSpec Puppet and currently are both faster and more accurate.

Puppet Check will also automatically download specified external module dependencies for and during RSpec Puppet testing. Currently `git`, `puppet forge`, `svn`, and `hg` commands are supported. They can be implemented in the following way in your modules' `metadata.json`:

```json
"dependencies": [
  {
    "name": "module-name",
    "forge": "forge-name",
    "args": "puppet module install optional-arguments"
  },
  {
    "name": "module-name",
    "git": "git-url",
    "args": "git clone optional-arguments"
  },
  {
    "name": "module-name",
    "hg": "hg-url",
    "args": "hg clone optional-arguments"
  },
  {
    "name": "module-name",
    "svn": "svn-url",
    "args": "svn co optional arguments"
  }
]
```

Example:

```json
"dependencies": [
  {
    "name": "puppetlabs/stdlib",
    "forge": "puppetlabs-stdlib",
    "args": "--do-something-cool"
  },
  {
    "name": "puppetlabs/lvm",
    "git": "https://github.com/puppetlabs/puppetlabs-lvm.git"
  }
]
```

Note that `args` will be ignored during `git pull`, `svn update`, and `hg pull/hg update` when the modules are updated instead of freshly cloned.

#### puppetcheck:beaker
This task serves as a frontend to the `beaker_quickstart:run_test[hypervisor]` rake task that Beaker provides. It merely provides a convenient unified frontend for the task and automated as part of the `puppetcheck` tasks. Note that you should still provide a hypervisor argument to the rake task when executed individually (e.g. `rake puppetcheck:beaker[vagrant]`). The Vagrant hypervisor will be selected by default when executed as part of the `puppetcheck` task. Vagrant will also be selected by default if no hypervisor argument is provided to the individual task.

#### puppetcheck:kitchen
This task serves as a frontend to the `kitchen:all` rake task that Test Kitchen provides. It merely provides a convenient unified frontend for the task and automated as part of the `puppetcheck` tasks.

### API

If you are performing your Puppet testing from within a Ruby script or your own custom Rakefile tasks, and want to execute Puppet Check intrinsically from the Ruby script or Rakefile, then you can call its API in the following simple way:

```ruby
# file checks
require 'puppet-check'

settings = {}
settings[:fail_on_warnings] = true # default false
settings[:style] = true # default false
settings[:smoke] = true # default false
settings[:regression] = true # in progress, do not use; default false
settings[:public] = 'public.pem' # default nil
settings[:private] = 'private.pem' # default nil
settings[:output_format] = 'yaml' # also 'json'; default 'text'
settings[:octoconfig] = '$HOME/octocatalog-diff.cfg.rb' # default '.octocatalog-diff.cfg.rb'
settings[:octonodes] = %w(server.example.com) # default: %w(localhost.localdomain)
settings[:puppetlint_args] = ['--puppetlint-arg-one', '--puppetlint-arg-two'] # default []
settings[:rubocop_args] = ['--except', 'rubocop-arg-one,rubocop-arg-two'] # default []

PuppetCheck.new.run(settings, [dirs, files])

# rspec checks (as part of a RSpec::Core::RakeTask.new block with |task|)
require 'puppet-check/rspec_puppet_support'

RSpecPuppetSupport.run
task.pattern = Dir.glob('**/{classes,defines,facter,functions,hosts,puppet,unit,types}/**/*_spec.rb').grep_v(/fixtures/)
```

### Docker

A supported [Docker image](https://hub.docker.com/r/matthewschuchard/puppet-check) of Puppet-Check is now available from the public Docker Hub registry. Please consult the repository documentation for further usage information.

### Vagrant

As an alternative to Docker, you can also use Vagrant for quick and disposable testing, but it is not as portable as Docker for these testing purposes. Below is an example `Vagrantfile` for this purpose.

```ruby
Vagrant.configure(2) do |config|
  # a reliable and small box at the moment
  config.vm.box = 'fedora/35-cloud-base'

  config.vm.provision 'shell', inline: <<-SHELL
    # cd to '/vagrant'
    cd /vagrant
    # you need ruby and any other extra dependencies that come from packages; in this example we install git to use it for downloading external module dependencies
    sudo dnf install ruby rubygems git -y
    # you need puppet-check and any other extra dependencies that come from gems; in this example we install rspec-puppet and rake for extra testing
    sudo gem install --no-document puppet-check rspec-puppet rake
    # this is needed for the ruby json parser to not flip out on fresh os installs for some reason (change encoding value as necessary)
    export LANG='en_US.UTF-8'
    # execute your tests; in this example we are executing the full suite of tests
    rake puppetcheck
  SHELL
end
```

To overcome the lack of convenient portability, you could try spinning up the Vagrant instance at the top level of your Puppet code and data and then descend into directories to execute tests as necessary. Cleverness or patience will be necessary if you decide to use Vagrant for testing and desire portability.

### Exit Codes
- 0: PuppetCheck exited with no internal exceptions or errors in your code and data.
- 1: PuppetCheck exited with an internal exception (takes preference over other non-zero exit codes) or failed spec test(s).
- 2: PuppetCheck exited with one or more errors in your code and data. Alternatively, PuppetCheck exited with one or more warnings in your code and data, and you specified to fail on warnings.

### Optional Dependencies
- **rake** (gem): install this if you want to use Puppet Check with `rake` tasks in addition to the CLI.
- **rspec** (gem): install this if you want to use Puppet Check to execute the spec tests for your Ruby files during `rake`.
- **rspec-puppet** (gem): install this if you want to use Puppet Check to execute the spec tests for your Puppet files during `rake`.
- **octocatalog-diff** (gem): install a version `>= 1.0` of this if you want to use Puppet Check to execute smoke or regression tests for your Puppet catalog.
- **beaker** (gem): install this if you want to use Puppet Check to execute the Beaker acceptance tests during `rake`.
- **test-kitchen** (gem): install this if you want to use Puppet Check to execute the Test Kitchen acceptance tests during `rake`.
- **git** (pkg): install this if you want to use Puppet Check to download external module dependencies with `git` commands during RSpec Puppet testing.
- **mercurial** (pkg): install this if you want to use Puppet Check to download external module dependencies with `hg` commands during RSpec Puppet testing.
- **subversion** (pkg): install this if you want to use Puppet Check to download external module dependencies with `svn` commands during RSpec Puppet testing.

## Contributing
Code should pass all spec tests. New features should involve new spec tests. Adherence to Rubocop and Reek is expected where not overly onerous or where the check is of dubious cost/benefit.

A [Dockerfile](Dockerfile) is provided for easy rake testing. A [Vagrantfile](Vagrantfile) is provided for easy gem building, installation, and post-installation testing.

Please consult the GitHub Project for the current development roadmap.
