#!/usr/bin/env ruby

if RUBY_VERSION < '2.0'
  STDERR.puts "Your version of ruby (#{RUBY_VERSION}) is crazy old, and autochrome definitely will not work; sorry."
  exit 1
end

require 'optparse'

$: << File.join(File.dirname(__FILE__), 'lib')
require 'auto_chrome'

def parse_options(arg_list)
  options = { profiles: [] }

  OptionParser.new do |opts|
    opts.banner = "Usage: #{File.basename($0)} [options] [\"profile 1\" [\"profile 2\" ...]]"
    opts.separator ""

    opts.on("-t", "--os-type OSTYPE", "Manually set operating system") do |t|
      options[:os_type] = t
    end

    opts.on("-V", "--chromium-version VERSION", "Set Chromium version to download") do |v|
      options[:cr_version] = v.to_i
    end

    opts.on("-l", "--force-download", "Download Chromium ignoring any cached versions") do |a|
      options[:force_download] = a
    end

    opts.on("-n", "--ignore-cache", "Don't cache downloads") do
      options[:ignore_cache] = true
    end

    opts.on("-f", "--chrome-archive FILE", "Specify a Chromium archive ZIP file") do |a|
      options[:chrome_archive] = a
    end

    opts.on("-P", "--profiles-only", "Install Profiles (and extensions) only; do not (re-)install Chromium") do
      options[:profiles_only] = true
    end

    opts.on("-d", "--installation-dir DIR", "Set directory to install Chromium to") do |d|
      options[:install_dir] = File.expand_path(d)
    end

    opts.on("-D", "--data-dir DIR", "Set directory to install profiles and extensions") do |d|
      options[:data_dir] = File.expand_path(d)
    end

    opts.on("-c", "--clobber", "Delete any existing Chromium installation") do
      options[:clobber] = true
    end

    opts.on("-p", "--proxy-host HOST", "Proxy host") do |p|
      options[:proxyhost] = p
    end

    opts.on("-p", "--proxy-base PORT", "Local proxy base port") do |p|
      options[:proxybase] = p.to_i
    end

    opts.on("-e", "--extensions EXTDIR", "Directory of bundled extensions") do |e|
      options[:extension_dir] = File.expand_path(e)
    end

    opts.on_tail("--list-themes", "List included themes") do
      pathglob = File.join(ProfileBuilder::BuiltinThemeDirectory, "*.crx")
      themes = Dir[pathglob].select {|f| File.file?(f)}.map do |f|
        File.basename(f).gsub("\.crx", "")
      end
      puts "Available themes are:"
      puts themes.join(", ")
      exit
    end

    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  # parse arg_list in order, non-destructively, and yield non-options
  end.order(arg_list) do |arg|
    options[:profiles] << arg
  end

  options
end

a = AutoChrome.new(parse_options(ARGV))
a.go


