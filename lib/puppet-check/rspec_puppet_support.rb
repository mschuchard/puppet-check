# class to prepare spec directory for rspec puppet testing
class RSpecPuppetSupport
  # code diagram:
  # 'puppetcheck:spec' task invokes 'run'
  # 'run' invokes 'file_setup' always and 'dependency_setup' if metadata.json exists
  # 'dependency_setup' invokes 'git/forge/hg' if dependencies exist and git/forge/hg is download option
  # 'git/forge/hg' downloads module fixture appropriately

  # prepare the spec fixtures directory for rspec-puppet testing
  def self.run
    # ensure this method does not do anything inside module dependencies
    specdirs = Dir.glob('**/spec').reject { |dir| dir =~ /fixtures/ }
    return if specdirs.class.to_s == 'NilClass'

    # setup fixtures for rspec-puppet testing
    specdirs.each do |specdir|
      # skip to next specdir if it does not seem like a puppet module
      next unless File.directory?(specdir + '/../manifests')

      # change to module directory
      Dir.chdir(specdir + '/..')

      # grab the module name from the directory name of the module to pass to file_setup
      file_setup(File.basename(Dir.pwd))

      # invoke dependency_setup for module dependencies if metadata.json present
      dependency_setup if File.file?('metadata.json')
    end
  end

  # setup the files, directories, and symlinks for rspec-puppet testing
  def self.file_setup(module_name)
    # create all the necessary fixture dirs that are missing
    ['spec/fixtures', 'spec/fixtures/manifests', 'spec/fixtures/modules', "spec/fixtures/modules/#{module_name}"].each do |dir|
      Dir.mkdir(dir) unless File.directory?(dir)
    end

    # create empty site.pp if missing
    File.write('spec/fixtures/manifests/site.pp', '') unless File.file?('spec/fixtures/manifests/site.pp')

    # symlink over everything the module needs for compilation
    %w(hiera.yaml data hieradata functions manifests lib files templates).each do |file|
      File.symlink("../../../../#{file}", "spec/fixtures/modules/#{module_name}/#{file}") if File.exist?(file) && !File.exist?("spec/fixtures/modules/#{module_name}/#{file}")
    end

    # create spec_helper if missing
    unless File.file?('spec/spec_helper.rb')
      File.open('spec/spec_helper.rb', 'w') { |file| file.puts "require 'rspec-puppet/spec_helper'\n" }
    end
  end

  # setup the module dependencies for rspec-puppet testing
  def self.dependency_setup
    require 'json'

    # parse the metadata.json (assumes DataParser.json has already given it a pass)
    parsed = JSON.parse(File.read('metadata.json'))

    # grab dependencies if they exist
    unless parsed['dependencies'].empty?
      parsed['dependencies'].each do |dependency_hash|
        # determine how the user wants to download the module dependency
        if dependency_hash.key?('git')
          git(dependency_hash['git'], dependency_hash['args'])
        elsif dependency_hash.key?('forge')
          forge(dependency_hash['forge'], dependency_hash['args'])
        elsif dependency_hash.key?('hg')
          hg(dependency_hash['hg'], dependency_hash['args'])
        else
          warn "#{dependency_hash['name']} has an unspecified, or specified but unsupported, download method."
        end
      end
    end
  end

  # download external module dependency with git
  def self.git(git_url, args = '')
    # establish path to clone module to
    path = "spec/fixtures/modules/#{File.basename(git_url, '.git')}"
    # is the module present and already cloned with git? do a pull; otherwise, do a clone
    File.dir?("#{path}/.git") ? system("git -C #{path} pull") : system("git clone #{args} #{git_url} #{path}")
  end

  # download external module dependency with forge
  def self.forge(forge_name, args = '')
    system("puppet module install --modulepath spec/fixtures/modules/ --force #{args} #{forge_name}")
  end

  # download external module dependency with hg
  def self.hg(hg_url, args = '')
    # establish path to clone module to
    path = "spec/fixtures/modules/#{File.basename(hg_url)}"
    # is the module present and already cloned with hg? do a pull and update; otherwise do a clone
    File.dir?("#{path}/.hg") ? system("hg --cwd #{path} pull; hg --cwd #{path} update") : system("hg clone #{args} #{hg_url} #{path}")
  end
end
