require 'fileutils'
require 'tmpdir'
require 'securerandom'
require 'base64'
require 'psych'

require_relative 'prefs'
require_relative 'chrome_extension'

IconColors = {
  "White"  => "chrome://theme/IDR_PROFILE_AVATAR_0",
  "Cyan"   => "chrome://theme/IDR_PROFILE_AVATAR_1",
  "Blue"   => "chrome://theme/IDR_PROFILE_AVATAR_2",
  "Green"  => "chrome://theme/IDR_PROFILE_AVATAR_3",
  "Orange" => "chrome://theme/IDR_PROFILE_AVATAR_4",
  "Purple" => "chrome://theme/IDR_PROFILE_AVATAR_5",
  "Red"    => "chrome://theme/IDR_PROFILE_AVATAR_6",
  "Yellow" => "chrome://theme/IDR_PROFILE_AVATAR_7",
}

class AutoChrome::Profile

  attr_reader :prefs, :secure_prefs, :dirname
  def initialize(opts={})
    @opts = opts
    @dirname = opts[:dirname] || SecureRandom.hex
    init_prefs

    @tmpdir = Dir.mktmpdir
  end

  def profile_entry
    hash = {
      "name" => @dirname,
    }
    if IconColors.keys.include? @dirname
      hash["avatar_icon"] = IconColors[@dirname]
    end
    [@dirname, hash]
  end

  def install_to(dir)
    write_preferences
    write_bookmarks

    if !File.exists?(dir)
      raise "Need valid installation directory"
    end

    FileUtils.move(@tmpdir, File.join(dir, @dirname))

    cleanup
  end

  def cleanup
    if @tmpdir && File.exists?(@tmpdir)
      FileUtils.remove_entry_secure(@tmpdir)
      @tmpdir = nil
    end
  end

  def set_theme(crx)
    @prefs['extensions.theme'] = { id: crx.id }
  end

  private

  def load_data(file, opts={})
    path = File.join(AutoChrome::DATA_BASE_DIR, "#{file}.yaml")
    data = File.read(path)
    Psych.load(data)
  end

  def init_prefs
    @prefs = AutoChrome::Prefs.new( load_data('default_prefs') )

    @secure_prefs = AutoChrome::SecurePrefs.new(nil, @opts)
    sprefs = load_data('default_secure_prefs')
    sprefs.each do |k,v| @secure_prefs[k] = v end
  end

  def write_preferences
    f = open(File.join(@tmpdir, "Preferences"), "w")
    f.write @prefs.to_json
    f.close

    f = open(File.join(@tmpdir, "Secure Preferences"), "w")
    f.write @secure_prefs.to_json
    f.close
  end

  def write_bookmarks
    if !@tmpdir
      raise "No temporary directory"
    end

    @gs_data_url ||= begin
      path = File.join(AutoChrome::DATA_BASE_DIR, "getting_started.html")
      html = File.read(path)
      b64  = Base64.strict_encode64(html).chomp
      "data:text/html;base64,#{b64}"
    end

    bookmarks = load_data('bookmarks')
    begin
      bookmarks["roots"]["bookmark_bar"]["children"].each do |bm|
        if bm['url'] == '__GETTING_STARTED__' then
          bm['url'] = @gs_data_url
        end
      end

      # Hack for extension to get profile name; TODO.
      bookmarks["roots"]["other"]["children"].each do |bm|
        bm['url'].gsub! /\A__PROFILE_NAME__\z/, "http://#{@dirname.gsub(/[^0-9a-zA-Z]/, "")}"
      end
    rescue => e
      STDERR.puts "failed to customize bookmarks: #{e}"
      raise e
    end

    f = open(File.join(@tmpdir, "Bookmarks"), "w")
    f.write bookmarks.to_json
    f.close
  end

  #not used
  def add_unpacked_extension(crx)
    if !@tmpdir
      raise "No temporary directory"
    end

    extract_dir = File.join(@tmpdir, "Extensions", crx.id, crx.version)
    FileUtils.mkdir_p(extract_dir)

    # use open3 to suppress unzip warnings for unexpected crx headers
    Open3.capture3("unzip", "-d", extract_dir, crx.path)

    @secure_prefs["extensions.settings.#{crx.id}"] = {
      manifest: crx.manifest,

    }

    return extract_dir
  end

end
