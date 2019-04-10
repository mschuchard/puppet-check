# PuppetCheck: automated rake testing in reproducible environment

# Build container to automatically provision environment and execute tests.
# sudo docker build -t puppetcheck .

# Start and enter container for troubleshooting if necessary.
# sudo docker run -it --rm puppetcheck (execute tests)
# sudo docker run -it --name puppetcheck -d puppetcheck (daemonize to enter container)
# sudo docker exec -it puppetcheck bash

# Remove running containers before rebuild.
# sudo docker ps -qa | xargs sudo docker stop

# Cleanup all instances when you are finished.
# sudo docker ps -qa | xargs sudo docker rm
# sudo docker images | grep puppetcheck | awk '{print $3}' | xargs sudo docker rmi

FROM fedora:28
RUN dnf install ruby -y && gem install --no-document puppet rubocop reek puppet-lint rspec rake octocatalog-diff
COPY / .
ENTRYPOINT ["rake"]
