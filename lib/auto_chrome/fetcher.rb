require 'net/https'
require 'rexml/document'
require 'tempfile'
require 'rbconfig'

# Class to download the most recent continuous integration build of
# Chromium for your platform.
#
# The following code autodetects the OS type and returns the downloaded
# binary as a File object:
#
#   c = AutoChrome::Fetcher.new
#   f = c.download_latest_chromium
#
class AutoChrome::Fetcher
  # These are the only useful ones available
  TypeZipMap = {
    "Linux_x64" => "chrome-linux.zip",
    "Mac" => "chrome-mac.zip",
    "Win" => "chrome-win32.zip",
    "Win_x64" => "chrome-win32.zip",
  }
  DefaultURL = "https://commondatastorage.googleapis.com/chromium-browser-snapshots/"

  def determine_latest_chromium
    uri = URI.join(@baseurl, "#{@type}/", 'LAST_CHANGE')

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER


    res = http.get(uri)

    if !res.instance_of? Net::HTTPOK
      puts "[!!!] Unable to get latest Chromium version, bailing"
      return nil
    end

    latestversion = res.body.to_i
    puts "[---] Got latest version: #{@type} #{latestversion}"
    latestversion > 0 ? latestversion : nil
  end

  # returns file object if successful
  def download_chromium(version, filename=nil)
    uri = URI.join(@baseurl, "#{@type}/", "#{version}/", TypeZipMap[@type])
    puts "[---] Downloading Chromium from %s" % [uri.to_s]

    if !filename
      # grab a random temp file instead
      f = Tempfile.new('chromium')
    else
      f = open(filename, "bw+")
    end
    begin
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER

      http.request_get(uri.path) do |res|
        if res.code != "200"
          puts "[!!!] Response code from Chromium build server was #{res.code}"
          return nil
        end

        downloaded = 0
        size = res.content_length
        res.read_body do |seg|
          f.write(seg)
          downloaded += seg.size
          outstring = []
          outstring << "\e[0G\e[2K"
          outstring << "[???] Saved % 9d of % 9s bytes" % [downloaded, size || "???"]
          if size
            outstring << " (%.1d%%)" % [(downloaded.to_f / size) * 100]
          end
          STDOUT.write outstring.join('')
          STDOUT.flush
        end
      end
    rescue
      f.close
      f.unlink
      return nil
    else
      f.flush
      f.rewind
    end
    # cleans up after the output above
    puts

    # return the file object for convenient unlinking
    f
  end

  def self.guess_type
    @guessed_type ||= begin
      os = RbConfig::CONFIG['host_os']

      case os
      when /darwin/
        puts "[???] Detected OS X"
        "Mac"
      when /linux/
        # Chromium only runs on 64-bit Linux, check this.
        cpu = RbConfig::CONFIG['host_cpu']
        if cpu == "x86_64"
          puts "[???] Detected Linux (x86_64)"
          "Linux_x64"
        else
          puts "[!!!] Linux builds are only available for x86_64 (you have #{cpu})"
          nil
        end
      else
        puts "[!!!] Unable to guess your platform from \"#{os}\""
        nil
      end
    end
  end

  # returns a tuple of file, type, version or nil
  def download_latest_chromium(filename=nil)
    puts "[---] Determining latest Chromium version for #{@type}"
    ver = determine_latest_chromium
    if !ver
      puts "[XXX] Can't download invalid version of Chromium"
      return nil
    end

    crfile = download_chromium(ver, filename)
    return nil if !crfile

    [crfile, ver]
  end

  def initialize(type=nil, baseurl=nil)
    type ||= self.guess_type
    if !TypeZipMap.keys.include?(type)
      puts "[XXX] The type specified (#{@type}) is invalid! Try one of #{TypeZipMap.keys.join " / "} instead."
      return nil
    end
    @type = type
    @baseurl = baseurl || DefaultURL
  end
end
