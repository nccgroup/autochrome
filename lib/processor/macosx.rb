require 'fileutils'
require_relative '../processor'

class ChromeProcessor::MacOSX < ChromeProcessor::UNIX
  ZipAppLocation = "chrome-mac/Chromium.app"
  FinalAppName = "Chromium.app"
  BinDirectory = "Contents/MacOS"
  AppBinary = "Chromium"
  DefaultFilesystemLocation = File.expand_path("~/Applications/")

  ChromeLocation = "/Applications/Google Chrome.app"

  def tweak_install
    if !@extdir
      raise "Need extracted directory"
    end

    bindir = File.expand_path(BinDirectory, @extdir)

    newbin = File.join(bindir, AppBinary)
    origname = AppBinary + "-orig"
    origbin = File.join(bindir, origname)

    # move the Chromium binary
    FileUtils.mv(newbin, origbin)

    # create Ruby shim script
    open(newbin, "w", 0755) do |f|
      f.write(<<-EOF)
#!/usr/bin/env ruby

ENV["GOOGLE_API_KEY"]="invalid"
ENV["GOOGLE_DEFAULT_CLIENT_ID"]="invalid"
ENV["GOOGLE_DEFAULT_CLIENT_SECRET"]="invalid"

opts = [
  "--ignore-certificate-errors",
  "--disable-xss-auditor",
  "--no-default-browser-check",
  "--no-first-run",
  "--disable-background-networking",
  "--disable-client-side-phishing-detection",
  "--disable-component-update",
  "--disable-sync",
  "--disable-translate",
  "--disable-web-resources",
  "--safebrowsing-disable-auto-update",
  "--safebrowsing-disable-download-protection",
  "--use-mock-keychain",
  "--proxy-server=#{@proxyhost}:#{@proxyport}",
  "--user-data-dir=#{@profiledir}",
]
opts.push *ARGV
exec(File.expand_path("#{origname}", File.dirname(__FILE__)), *opts)
      EOF
    end
  end

  def launch_instructions
    puts "
To launch Chromium, run 'open #{@installdir}' in a terminal.
You can also type \"Chromium\" into Spotlight."
  end
end
