# PuppetCheck: automated rake testing in reproducible environment

# Build container to automatically provision environment and execute tests.
# sudo docker build -t puppetcheck .

# Start and enter container for troubleshooting if necessary.
# sudo docker run -it --rm puppetcheck (execute tests)
# sudo docker run -it -d puppetcheck (daemonize to enter container)
# sudo docker exec -it puppetcheck bash

# Remove running containers before rebuild.
# sudo docker ps -qa | xargs sudo docker kill

# Cleanup all instances when you are finished.
# sudo docker ps -qa | xargs sudo docker rm
# sudo docker images | grep puppetcheck | awk '{print $3}' | xargs sudo docker rmi

FROM fedora:23
RUN dnf install ruby -y
RUN gem install --no-rdoc --no-ri puppet rubocop reek puppet-lint spdx-licenses rspec rake
COPY / .
ENTRYPOINT ["rake"]
