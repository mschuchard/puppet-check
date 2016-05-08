# PuppetCheck: automated rake testing in reproducible environment

# Build container to automatically provision environment and execute tests.
# sudo docker build -t puppetcheck .

# Start and enter container for troubleshooting if necessary.
# sudo docker run -it -d puppetcheck
# sudo docker exec -it `sudo docker ps -qa | awk '{print $1}' | head -n 1` bash

# Remove running containers before rebuild.
# sudo docker ps -qa | xargs sudo docker kill

# Cleanup all instances when you are finished.
# sudo docker ps -qa | xargs sudo docker rm
# sudo docker images | grep puppetcheck | awk '{print $3}' | xargs sudo docker rmi

FROM ubuntu:15.10
RUN apt-get update && apt-get install ruby -y
RUN gem install --no-rdoc --no-ri puppet rspec rake rubocop reek puppet-lint spdx-licenses
COPY / /
# Exit 0 to ensure container is built with tag for troubleshooting.
RUN rake; exit 0
