require 'fileutils'
require 'tmpdir'
require_relative '../fake_json'
require_relative '../cr_ext'

class ChromeProfileManager
  BuiltinExtensionDirectory = File.expand_path("../../../data/extensions", __FILE__)

  def initialize(opts={})
    @opts = opts
    @installdir = opts[:data_dir]
    @clobber = opts[:clobber] || opts[:profiles_only]
    @extensiondir = opts[:extension_dir] || BuiltinExtensionDirectory
    @profile_names = opts[:profiles]
  end

  def tmpdir
    @tmpdir ||= Dir.mktmpdir.tap do |dir|
      FileUtils.mkdir_p(File.expand_path(dir))
    end
  end

  # The reason this is here is that detecting a running Chromium
  # happens via the profile directory. The Processor doesn't know
  # about profiles, so it's up to the Profile Manager.
  def current_chromium_pid
    process = File.expand_path("SingletonLock", @installdir)
    if File.symlink?(process)
      pid = File.readlink(process).split("-")[1]
      if pid.to_i == 0
        pid = "unknown"
      end
    end

    pid
  end

  def generate
    if @profile_names.empty?
      @profile_names = %w(Red Yellow Blue)
    end
    @profile_names.map! do |name|
      File.basename(name)
    end

    @profiles = @profile_names.map do |i|
      ChromeProfile.new(os_type: @opts[:os_type], dirname: i)
    end
    @profiles.each &:generate
  end

  def add_extensions
    exts = Dir[File.join(@extensiondir, "*.crx")].select {|f| File.file?(f)}
    return if exts.empty?

    extensioninstalldir = File.join(@installdir, "External Extensions")
    @tmpextdir = File.join(tmpdir, "External Extensions")
    FileUtils.mkdir_p(@tmpextdir)

    exts.each do |e|
      puts "[---] Installing extension #{File.basename(e)}"

      key = CrExt.get_crx_key(e)
      id = CrExt.calculate_crx_id(key)
      crxname = "#{id}.crx"
      installedpath = File.join(extensioninstalldir, crxname)

      # generate External Extension file
      j = {
        "external_crx" => installedpath,
        "external_version" => CrExt.get_crx_version(e),
      }.to_json
      open(File.join(@tmpextdir, "#{id}.json"), "w") do |f|
        f.write(j)
      end

      @profiles.each do |p|
        p.secure_prefs["extensions.settings.#{id}"] = {ack_external: true}
      end

      # rename and copy to folder
      FileUtils.cp(e, File.join(@tmpextdir, crxname))
    end
  end

  def install
    if !@profiles
      raise "No profiles to install"
    end

    @profiles.each do |p|
      p.install(tmpdir)
    end

    profileobj = generate_local_state_profiles
    setup_local_state(profileobj)

    if @clobber
      if File.exists? @installdir
        FileUtils.remove_entry_secure(@installdir)
      end
    elsif needs_to_clobber?
      raise "Not clobbering existing profile directory"
    end

    FileUtils.move(tmpdir, @installdir)
    @tmpdir = nil #XXX should prevent reuse of manager instead?

    puts "[---] Installed user profiles"
  end

  def cleanup
    if @tmpdir && File.exists?(@tmpdir)
      FileUtils.remove_entry_secure(@tmpdir)
      @tmpdir = nil
    end

    if @profiles
      @profiles.each do |p|
        p.cleanup
      end
      @profiles = []
    end
  end

  def needs_to_clobber?
    File.exists? @installdir
  end

  private

  def generate_local_state_profiles
    if @profiles.size < 1
      puts "[!!!] Didn't get any profiles to bundle"
      return {}
    end

    entries = Hash[@profiles.map &:profile_entry]

    {
      "profile" => {
        "info_cache" => entries,
        "last_used" => entries.keys.first,
      }
    }
  end

  def setup_local_state(args={})
    obj = {
      "browser" => {
        "confirm_to_quit" => true,
        "enabled_labs_experiments" => [
          "enable-brotli@2",
        ],
      },
    }.merge(args)

    f = open(File.join(@tmpdir, "Local State"), "w")
    f.write(obj.to_json)
    f.close
  end

  def self.get_default_directory(type)
    case type
    when "Mac"
      default = "~/Library/Application Support/Chromium"
    when "Linux_x64"
      default = "~/.config/autochrome"
    else
      raise NotImplementedException
    end
    File.expand_path(default)
  end
end
