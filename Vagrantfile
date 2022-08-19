# PuppetCheck: testing gem build, install, and execution
Vagrant.configure(2) do |config|
  config.vm.box = 'debian/bullseye64'

  config.vm.provision 'shell', inline: <<-SHELL
    cd /vagrant
    apt-get install -y ruby-dev make gcc
    gem build puppet-check.gemspec
    gem install --no-document puppet-check*.gem
    rm -f puppet-check*.gem
    cd spec/fixtures
    /usr/local/bin/puppet-check -s .
    echo $?
  SHELL
end
