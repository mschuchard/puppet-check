# PuppetCheck: testing gem build, install, and execution
Vagrant.configure(2) do |config|
  config.vm.box = 'centos/7'

  config.vm.provision 'shell', inline: <<-SHELL
    cd /vagrant
    yum install ruby rubygems -y
    gem build puppet-check.gemspec
    gem install --no-rdoc --no-ri rubocop -v 0.50
    gem install --no-rdoc --no-ri rake puppet-check*.gem
    gem install --no-rdoc --no-ri reek -v 3.11
    rm -f puppet-check*.gem
    cd spec/fixtures
    /usr/local/bin/puppet-check -s .
    echo $?
  SHELL
end
