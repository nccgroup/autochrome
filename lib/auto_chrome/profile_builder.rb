require 'fileutils'
require 'tmpdir'

require_relative 'profile'
require_relative 'chrome_extension'

class AutoChrome::ProfileBuilder
  BuiltinExtensionDirectory = File.expand_path("../../../data/extensions", __FILE__)
  BuiltinThemeDirectory = File.expand_path("../../../data/themes", __FILE__)

  def initialize(opts={})
    @opts = opts
    @install_dir = opts[:data_dir]
    @clobber = opts[:clobber] || opts[:profiles_only]
    @extensiondir = opts[:extension_dir] || BuiltinExtensionDirectory
    @profile_names = opts[:profiles]
  end



  def generate
    if @profile_names.empty?
      @profile_names = %w(Red Yellow Blue Cyan Green Orange Purple White)
    end

    @profiles = @profile_names.map do |name|
      AutoChrome::Profile.new(os_type: @opts[:os_type], dirname: name)
    end
  end

  def add_themes
    raise 'call "generate" first' unless @profiles

    @profiles.each do |p|
      theme_path = File.join(BuiltinThemeDirectory, "#{p.dirname}.crx")
      unless File.exists? theme_path
        STDERR.puts "no theme for profile '#{p.dirname}' at path '#{theme_path}'"
      else
        theme_crx = AutoChrome::ChromeExtension.new(theme_path)
        add_extension(theme_crx, [p])
        p.set_theme(theme_crx)
      end
    end
  end

  def add_extensions
    Dir[File.join(@extensiondir, "*.crx")].each do |crx_path|
      next unless File.file?(crx_path)
      crx = AutoChrome::ChromeExtension.new(crx_path)
      add_extension(crx, @profiles)
    end
  end

  def install
    if !@profiles
      raise "No profiles to install"
    end

    @profiles.each do |p|
      p.install_to(staging_dir)
    end

    profileobj = generate_local_state_profiles
    setup_local_state(profileobj)

    stub_avatar_icons

    if @clobber
      if File.exists? @install_dir
        FileUtils.remove_entry_secure(@install_dir)
      end
    elsif needs_to_clobber?
      raise "Not clobbering existing profile directory"
    end

    FileUtils.mkdir_p(File.dirname(@install_dir))

    FileUtils.move(staging_dir, @install_dir)

    puts "[---] Installed user profiles"
  end

  def cleanup
    if staging_dir && File.exists?(staging_dir)
      FileUtils.remove_entry_secure(staging_dir)
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

  def staging_dir(subdir=nil)
    @temp_root ||= Dir.mktmpdir.tap {|d| FileUtils.mkdir_p(d) }
    if (subdir)
      File.join(@temp_root, subdir).tap {|d| FileUtils.mkdir_p(d) }
    else
      @temp_root
    end
  end

  def add_extension(crx, profiles)
    puts "[---] Installing extension #{crx.path}"

    working_dir = staging_dir('External Extensions')
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
    #XXX this will break if we call add_extension multiple times with the same
    #extension and different profiles
    (@profiles - profiles).each do |p|
      p.secure_prefs["extensions.settings.#{crx.id}"] = {
        disable_reasons: 1, # DISABLE_USER_ACTION
        state: 0
      }
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
          "show-cert-link",
        ],
      },
      "network_time" => {
        "network_time_queries_enabled" => false,
      },
    }.merge(args)

    File.write(File.join(staging_dir, 'Local State'), obj.to_json)
  end

  # Chromium downloads hi-res icons for profiles because they're
  # not shipped with Chromium by default. If we make zero-length
  # files with the right name, it just uses the low-res placeholders.
  def stub_avatar_icons
    dir = staging_dir('Avatars')

    [
      "avatar_generic.png",
      "avatar_generic_aqua.png",
      "avatar_generic_blue.png",
      "avatar_generic_green.png",
      "avatar_generic_orange.png",
      "avatar_generic_purple.png",
      "avatar_generic_red.png",
      "avatar_generic_yellow.png",
    ].each do |icon|
      open(File.join(dir, icon), "w")
    end
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
