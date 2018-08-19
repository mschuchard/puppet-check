# PuppetCheck: testing gem build, install, and execution
Vagrant.configure(2) do |config|
  config.vm.box = 'opensuse/openSUSE-42.2-x86_64'

  config.vm.provision 'shell', inline: <<-SHELL
    cd /vagrant
    zypper --non-interactive install ruby2.1-devel
    gem build puppet-check.gemspec
    gem install --no-document rubocop -v 0.57.2
    gem install --no-document rake puppet-check*.gem
    rm -f puppet-check*.gem
    cd spec/fixtures
    /usr/bin/puppet-check.ruby2.1 -s .
    echo $?
  SHELL
end
