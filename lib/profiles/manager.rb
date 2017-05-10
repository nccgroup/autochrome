require 'fileutils'
require 'tmpdir'
require_relative '../fake_json'
require_relative '../chrome_extension'

class ChromeProfileManager
  BuiltinExtensionDirectory = File.expand_path("../../../data/extensions", __FILE__)
  BuiltinThemeDirectory = File.expand_path("../../../data/themes", __FILE__)

  def initialize(opts={})
    @opts = opts
    @install_dir = opts[:data_dir]
    @clobber = opts[:clobber] || opts[:profiles_only]
    @extensiondir = opts[:extension_dir] || BuiltinExtensionDirectory
    @profile_names = opts[:profiles]
  end

  def temp_dir(subdir=nil)
    @temp_root ||= Dir.mktmpdir.tap {|d| FileUtils.mkdir_p(d) }
    if (subdir)
      File.join(@temp_root, subdir).tap {|d| FileUtils.mkdir_p(d) }
    else
      @temp_root
    end
  end

  # The reason this is here is that detecting a running Chromium
  # happens via the profile directory. The Processor doesn't know
  # about profiles, so it's up to the Profile Manager.
  def current_chromium_pid
    process = File.expand_path("SingletonLock", @install_dir)
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

    @profiles = @profile_names.map do |name|
      p = ChromeProfile.new(os_type: @opts[:os_type], dirname: name)
      p.generate

      theme_path = File.join(BuiltinThemeDirectory, "#{name}.crx")
      unless File.exists? theme_path
        STDERR.puts "no theme for profile '#{name}' at path '#{theme_path}'"
      else
        theme_crx = ChromeExtension.new(theme_path)
        add_extension(theme_crx, [p])
        p.set_theme(theme_crx)
      end
      p
    end
  end

  def add_extensions
    Dir[File.join(@extensiondir, "*.crx")].each do |crx_path|
      next unless File.file?(crx_path)
      crx = ChromeExtension.new(crx_path)
      add_extension(crx, @profiles)
    end
  end

  def install
    if !@profiles
      raise "No profiles to install"
    end

    @profiles.each do |p|
      p.install(temp_dir)
    end

    profileobj = generate_local_state_profiles
    setup_local_state(profileobj)

    if @clobber
      if File.exists? @install_dir
        FileUtils.remove_entry_secure(@install_dir)
      end
    elsif needs_to_clobber?
      raise "Not clobbering existing profile directory"
    end

    FileUtils.move(temp_dir, @install_dir)

    puts "[---] Installed user profiles"
  end

  def cleanup
    if temp_dir && File.exists?(temp_dir)
      FileUtils.remove_entry_secure(temp_dir)
    end

    if @profiles
      @profiles.each do |p|
        p.cleanup
      end
      @profiles = []
    end
  end

  def needs_to_clobber?
    File.exists? @install_dir
  end

  private

  def add_extension(crx, profiles)
    puts "[---] Installing extension #{crx.path}"

    working_dir = temp_dir('External Extensions')
    working_json_path = File.join(working_dir, "#{crx.id}.json")
    working_crx_path = File.join(working_dir, "#{crx.id}.crx")

    final_dir = File.join(@install_dir, 'External Extensions')
    final_crx_path = File.join(final_dir, "#{crx.id}.crx")

    # generate External Extension file
    File.write(working_json_path, JSON.generate({
      external_crx: final_crx_path,
      external_version: crx.version
    }))

    # bypass extension confirmation prompts
    profiles.each do |p|
      p.secure_prefs["extensions.settings.#{crx.id}"] = {ack_external: true}
    end

    # rename and copy to working folder
    FileUtils.cp(crx.path, working_crx_path)
  end


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

    File.write(File.join(temp_dir, 'Local State'), obj.to_json)
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
