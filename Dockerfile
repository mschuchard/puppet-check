# PuppetCheck: automated rake testing in reproducible environment
FROM fedora:36
RUN dnf install ruby -y && gem install --no-document puppet rubocop reek puppet-lint rspec rake octocatalog-diff
COPY / .
ENTRYPOINT ["rake"]
