# class to prepare spec directory for rspec puppet testing
class RSpecPuppetSupport
  # code diagram for RSpecPuppetSupport:
  # puppetcheck:spec task invokes run
  # run invokes file_setup always and dependency_setup if metadata.json exists
  # dependency_setup invokes git/forge/hg if git/forge/hg is download option and dependencies exist

  # prepare the spec fixtures directory for rspec-puppet testing
  def self.run
    # ensure this method does not do anything inside module dependencies
    specdirs = Dir.glob('**/spec').reject { |dir| dir =~ /fixtures/ }
    return if specdirs.class.to_s == 'NilClass'

    # setup fixtures for rspec-puppet testing
    specdirs.each do |specdir|
      # skip to next specdir if it does not seem like a puppet module
      next unless File.directory?(specdir + '/../manifests')

      # move up to module directory
      Dir.chdir(specdir + '/..')

      # grab the module name from the directory name of the module to pass to file_setup
      file_setup(File.basename(Dir.pwd))

      # invoke dependency_setup for module dependencies if metadata.json present
      dependency_setup if File.file?('metadata.json')
    end
  end

  # setup the files, directories, and symlinks for rspec-puppet testing
  def self.file_setup(module_name)
    require 'fileutils'

    # create all the necessary fixture dirs that are missing
    ['spec/fixtures', 'spec/fixtures/manifests', 'spec/fixtures/modules', "spec/fixtures/modules/#{module_name}"].each do |dir|
      FileUtils.mkdir(dir) unless File.directory?(dir)
    end

    # create empty site.pp if missing
    FileUtils.touch('spec/fixtures/manifests/site.pp') unless File.file?('spec/fixtures/manifests/site.pp')

    # symlink over everything the module needs for compilation
    %w(hiera.yaml data hieradata functions manifests lib files templates).each do |file|
      FileUtils.ln_s("../../../../#{file}", "spec/fixtures/modules/#{module_name}/#{file}") if File.exist?(file) && !File.exist?("spec/fixtures/modules/#{module_name}/#{file}")
    end

    # create spec_helper if missing
    unless File.file?('spec/spec_helper.rb')
      File.open('spec/spec_helper.rb', 'w') { |file| file.puts "require 'rspec-puppet/spec_helper'\n" }
    end
  end

  # setup the module dependencies for rspec-puppet testing
  def self.dependency_setup
    require 'json'

    # parse the metadata.json (assumes PuppetCheck file checks have already given it a pass)
    parsed = JSON.parse(File.read('metadata.json'))

    # grab dependencies if they exist
    unless parsed['dependencies'].empty?
      parsed['dependencies'].each do |dependency_hash|
        # determine how the user wants to download the module dependency
        if dependency_hash.key?('git')
          git(dependency_hash['git'])
        elsif dependency_hash.key?('forge')
          forge(dependency_hash['forge'])
        elsif dependency_hash.key?('hg')
          hg(dependency_hash['hg'])
        else
          warn "#{dependency_hash['name']} has an unspecified, or specified but unsupported, download method."
        end
      end
    end
  end

  # download external module dependency with git
  def self.git(git_url)
    system("git -C spec/fixtures/modules/ clone #{git_url}")
  end

  # download external module dependency with forge
  def self.forge(forge_name)
    system("puppet module install #{forge_name} --modulepath spec/fixtures/modules/ --force")
  end

  # download external module dependency with hg
  def self.hg(hg_url)
    system("hg --cwd spec/fixtures/modules/ clone #{hg_url}")
  end
end
