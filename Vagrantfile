# PuppetCheck: testing gem build, install, and execution
Vagrant.configure(2) do |config|
  config.vm.box = 'opensuse/openSUSE-42.2-x86_64'

  config.vm.provision 'shell', inline: <<-SHELL
    cd /vagrant
    zypper install ruby2.1-devel -y
    gem build puppet-check.gemspec
    gem install --no-rdoc --no-ri rake puppet-check*.gem
    rm -f puppet-check*.gem
    cd spec/fixtures
    /usr/local/bin/puppet-check -s .
    echo $?
  SHELL
end
