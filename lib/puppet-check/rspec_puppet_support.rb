# class to prepare spec directory for rspec puppet testing
class RSpecPuppetSupport
  # code diagram:
  # 'puppetcheck:spec' task invokes 'run'
  # 'run' invokes 'file_setup' always and 'dependency_setup' if metadata.json exists
  # 'dependency_setup' invokes 'git/forge/hg' if dependencies exist and git/forge/hg is download option
  # 'git/forge/svn/hg' downloads module fixture appropriately

  # prepare the spec fixtures directory for rspec-puppet testing
  def self.run
    # ensure this method does not do anything inside module dependencies
    specdirs = Dir.glob('**/spec').reject { |dir| dir =~ /fixtures/ }
    return if specdirs.empty?

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
    private_class_method :method
    # create all the necessary fixture dirs that are missing
    ['spec/fixtures', 'spec/fixtures/manifests', 'spec/fixtures/modules'].each do |dir|
      Dir.mkdir(dir) unless File.directory?(dir)
    end

    # create empty site.pp if missing
    File.write('spec/fixtures/manifests/site.pp', '') unless File.file?('spec/fixtures/manifests/site.pp')

    # symlink the module into spec/fixtures/modules
    File.symlink("../../../#{module_name}", "spec/fixtures/modules/#{module_name}") unless File.exist?("spec/fixtures/modules/#{module_name}")

    # create spec_helper if missing
    return if File.file?('spec/spec_helper.rb')
    File.open('spec/spec_helper.rb', 'w') { |file| file.puts "require 'rspec-puppet'\n\nfixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))\n\nRSpec.configure do |c|\n  c.module_path     = File.join(fixture_path, 'modules')\n  c.manifest_dir    = File.join(fixture_path, 'manifests')\n  c.manifest        = File.join(File.dirname(File.expand_path(__FILE__)), 'fixtures', 'manifests', 'site.pp')\n  c.environmentpath = File.join(Dir.pwd, 'spec')\nend" }
  end

  # setup the module dependencies for rspec-puppet testing
  def self.dependency_setup
    private_class_method :method
    require 'json'

    # parse the metadata.json (assumes DataParser.json has already given it a pass)
    parsed = JSON.parse(File.read('metadata.json'))

    # grab dependencies if they exist
    return if parsed['dependencies'].empty?
    parsed['dependencies'].each do |dependency_hash|
      # determine how the user wants to download the module dependency
      if dependency_hash.key?('git')
        git(dependency_hash['git'], dependency_hash['args'])
      elsif dependency_hash.key?('forge')
        forge(dependency_hash['forge'], dependency_hash['args'])
      elsif dependency_hash.key?('svn')
        svn(dependency_hash['svn'], dependency_hash['args'])
      elsif dependency_hash.key?('hg')
        hg(dependency_hash['hg'], dependency_hash['args'])
      else
        warn "#{dependency_hash['name']} has an unspecified, or specified but unsupported, download method."
      end
    end
  end

  # download external module dependency with git
  def self.git(git_url, args = '')
    private_class_method :method
    # establish path to clone module to
    path = "spec/fixtures/modules/#{File.basename(git_url, '.git')}"
    # is the module present and already cloned with git? do a pull; otherwise, do a clone
    File.directory?("#{path}/.git") ? system("git -C #{path} pull") : system("git clone #{args} #{git_url} #{path}")
  end

  # download external module dependency with forge
  def self.forge(forge_name, args = '')
    private_class_method :method
    # is the module present? do an upgrade; otherwise, do an install
    subcommand = File.directory?("spec/fixtures/modules/#{forge_name}") ? 'upgrade' : 'install'
    system("puppet module #{subcommand} --modulepath spec/fixtures/modules/ #{args} #{forge_name}")
  end

  # download external module dependency with svn
  def self.svn(svn_url, args = '')
    private_class_method :method
    # establish path to checkout module to
    path = "spec/fixtures/modules/#{File.basename(svn_url)}"
    # is the module present and already checked out with svn? do an update; otherwise, do a checkout
    File.directory?("#{path}/.svn") ? system("svn update #{path}") : system("svn co #{args} #{svn_url} #{path}")
  end

  # download external module dependency with hg
  def self.hg(hg_url, args = '')
    private_class_method :method
    # establish path to clone module to
    path = "spec/fixtures/modules/#{File.basename(hg_url)}"
    # is the module present and already cloned with hg? do a pull and update; otherwise do a clone
    File.directory?("#{path}/.hg") ? system("hg --cwd #{path} pull; hg --cwd #{path} update") : system("hg clone #{args} #{hg_url} #{path}")
  end
end
