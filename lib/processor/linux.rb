require 'fileutils'
require_relative '../processor'

class ChromeProcessor::Linux < ChromeProcessor::UNIX
  ZipAppLocation = "chrome-linux"
  FinalAppName = "autochrome"
  AppBinary = "chrome"
  WrapperScript = "chrome-wrapper"
  DefaultFilesystemLocation = File.expand_path("~/.local/")

  def sanity_check
    super
    if `sysctl -n kernel.unprivileged_userns_clone`.chomp != "1"
      STDERR.puts "[!!!] WARNING: Namespace sandboxes are not available.  Please run the following as root to fix:"
      STDERR.puts "[!!!]   sysctl kernel.unprivileged_userns_clone=1"
      STDERR.puts "[!!!] Otherwise, the Chromium sandbox will be disabled."
    end
  end

  def tweak_install
    if !@extdir
      raise "Need extracted directory"
    end

    newbin = File.join(@extdir, AppBinary)
    origname = AppBinary + "-orig"
    origbin = File.join(@extdir, origname)

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
  "--proxy-server=#{@proxyhost}:#{@proxyport}",
  "--user-data-dir=#{@profiledir}",
]

if Process.uid == 0
  STDERR.puts "WARNING: sandbox disabled due to running as root"
  opts.push "--no-sandbox"
elsif `sysctl -n kernel.unprivileged_userns_clone`.chomp != "1"
  STDERR.puts "WARNING: sandbox disabled due to kernel.unprivileged_userns_clone=0"
  opts.push "--no-sandbox"
end

opts.push *ARGV
exec(File.expand_path("#{origname}", File.dirname(__FILE__)), *opts)
      EOF
    end

    wrapper = File.join(@extdir, WrapperScript)
    contents = open(wrapper) {|f| f.read}
    contents.gsub!(/^TITLE=.+$/, 'TITLE="Autochrome"')
    contents.gsub!(/^DESKTOP=.+$/, 'DESKTOP="autochrome"')
    open(wrapper, "w") {|f| f.write(contents)}
  end

  def launch_instructions
    path = File.expand_path(File.join(@installdir, WrapperScript))
    puts "
To launch Chromium, run '#{path}' in a terminal.
The application may not appear in your launcher until you log out."
  end
end
