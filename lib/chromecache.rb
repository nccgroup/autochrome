require 'rbconfig'

class ChromeCache
  def available?(version=nil)
    false
  end

  def get_cache(version=nil)
    raise NotImplementedError
  end

  def update(crfile, version)
    true
  end

  # Only cache if the type matches the host
  def self.get_host(type)
    os ||= RbConfig::CONFIG['host_os']
    case os
    when /darwin/
      if type == "Mac"
        return type
      end
    when /linux/
      if type == "Linux_x64"
        return type
      end
    else
      raise NotImplementedException
    end
  end

  def self.new_from_type(type)
    case self.get_host(type)
    when "Mac"
      MacChromeCache.new
    when "Linux_x64"
      XDGChromeCache.new
    else
      ChromeCache.new
    end
  end
end

class UnixChromeCache < ChromeCache
  def available?(version=nil)
    return false if !File.directory?(@dir)

    caches = get_cache_files

    if version
      caches.has_key?(version)
    else
      two_weeks_ago = Time.now - 60 * 60 * 24 * 14
      recent = caches.any? do |v,f|
        stats = File.stat(f)
        stats.ctime > two_weeks_ago
      end

      if !recent && caches.size > 0
        puts "[---] Cache is out of date!"
      end

      recent
    end
  end

  def get_cache(version=nil)
    caches = get_cache_files

    if version.nil?
      version = caches.keys.last
    end
    file = caches[version]

    [open(file, "rb"), version]
  end

  def update(crfile, version)
    wipe_cache
    FileUtils.mkdir_p(@dir)
    FileUtils.cp(crfile, File.join(@dir, "chrome-#{@host}-#{version}.zip"))
  end

  private

  def wipe_cache
    if Dir.exists?(@dir)
      FileUtils.remove_entry_secure(@dir)
    end
  end

  def get_cache_files
    files = Dir.glob(File.join(@dir, "chrome-#{@host}-*.zip"))
    versions = files.map {|f| [get_file_version(f), f]}

    valid = versions.map do |v, f|
      if v && v > 0
        [v,f]
      end
    end.reject(&:nil?).sort

    Hash[valid]
  end

  def get_file_version(filename)
    begin
      File.basename(filename).split(/[-.]/)[2].to_i
    rescue
      nil
    end
  end
end

class MacChromeCache < UnixChromeCache
  CacheDirectory = "~/Library/Caches/Autochrome"

  def initialize
    @dir = File.expand_path(CacheDirectory)
    @host = "Mac"
  end
end

# See https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
class XDGChromeCache < UnixChromeCache
  CacheRootDirectory = "~/.cache"

  def initialize
    cache_root = File.expand_path(ENV["XDG_CACHE_HOME"] || CacheRootDirectory)
    @dir = File.join(cache_root, "autochrome")
    @host = "Linux"
  end
end
