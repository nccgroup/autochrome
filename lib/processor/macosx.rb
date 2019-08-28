require 'fileutils'
require_relative '../processor'

class ChromeProcessor::MacOSX < ChromeProcessor::UNIX
  ZipAppLocation = "chrome-mac/Chromium.app"
  FinalAppName = "Chromium.app"
  BinDirectory = "Contents/MacOS"
  AppBinary = "Chromium"
  FrameworkBinaryGlob = 'Contents/Frameworks/Chromium Framework.framework/Versions/Current/Chromium Framework'
  DefaultFilesystemLocation = File.expand_path("~/Applications/")

  ChromeLocation = "/Applications/Google Chrome.app"

  def sanity_check
    # nothing to do here now
    super
  end

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

    # patch out unoverridable flags for webstore-only extensions
    framework_glob = File.expand_path(FrameworkBinaryGlob, @extdir)
    framework_fn = Dir.glob(framework_glob).first
    raise "Can't find framework file at #{framework_glob} to patch" unless File.exist? framework_fn
    framework_bin = File.read(framework_fn, encoding: 'binary')
    framework_bin.sub! 'ExtensionInstallVerification', 'ExtensionInstallVerificati_1'
    framework_bin.sub! 'ExtensionInstallVerification', 'ExtensionInstallVerificati_2'
    File.write(framework_fn, framework_bin)

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

if Process.uid == 0
  STDERR.puts "WARNING: sandbox disabled due to running as root"
  opts.push "--no-sandbox"
end

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
