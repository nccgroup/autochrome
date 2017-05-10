require 'fileutils'
require 'optparse'
require 'pp'

require_relative 'chromecache'
require_relative 'fetch_cr'
require_relative 'processor'
require_relative 'profiles'

class AutoChrome
  def check_type(type)
    FetchCr::TypeZipMap.key? type
  end

  def get_chrome(opts)
    if opts[:chrome_archive]
      begin
        return [open(opts[:chrome_archive], "rb"), nil]
      rescue
        abort "[!!!] Unable to open Chrome archive"
      end
    end

    version = opts[:cr_version]

    cache = ChromeCache.new_from_type(opts[:os_type])
    if !opts[:force_download]
      if cache.available?(version)
        crfile, version = cache.get_cache(version)
        puts "[---] Using locally cached Chromium version #{version}"
        return [crfile, version]
      end
    end

    c = FetchCr.new(opts[:os_type])
    if version
      crfile = c.download_chromium(version)
    else
      crfile, version = c.download_latest_chromium
    end

    if !crfile
      abort "[!!!] Failed download, terminating program"
    end

    cache.update(crfile, version) unless opts[:ignore_cache]
    [crfile, version]
  end

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

      opts.on("-p", "--proxy-base PORT", "Local proxy base port") do |p|
        options[:proxybase] = p.to_i
      end

      opts.on("-e", "--extensions EXTDIR", "Directory of bundled extensions") do |e|
        options[:extension_dir] = File.expand_path(e)
      end

      opts.on_tail("--list-themes", "List included themes") do
        pathglob = File.join(ChromeProfileGenerator::BuiltinThemeDirectory, "*.crx")
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

  def go
    unless @options[:profiles_only]
      crfile, version = get_chrome(@options)
      @processor.unpack(crfile)
      @processor.tweak_install
      @processor.install
    end

    @profiles.generate
    @profiles.add_extensions
    @profiles.install

    unless @options[:profiles_only]
      @processor.launch_instructions
      global_launch_instructions
    end
  ensure
    unless @options[:profiles_only]
      @processor.cleanup
    end
    @profiles.cleanup
  end

  def initialize(opts)
    @options = case opts
    when Hash
      opts
    when Array
      parse_options(opts)
    else
      raise "bad opts"
    end

    # type must be set before doing useful things
    type = @options[:os_type] || FetchCr.guess_type
    if !check_type(type)
      if @options[:os_type]
        puts "[XXX] The type specified was #{@options[:os_type]}."
      else
        puts "[XXX] Your operating system couldn't be determined!"
      end
      abort "[XXX] OS type needs to be one of #{FetchCr::TypeZipMap.keys.join(" / ")}."
    end
    @options[:os_type] = type
    @options[:data_dir] ||= ChromeProfileManager.get_default_directory(type)

    unless @options[:profiles_only]
      @processor = ChromeProcessor.new_from_type(@options)
      if !@processor
        abort "[XXX] Unable to create processor"
      end
    end

    @profiles = ChromeProfileManager.new(@options)

    # do a quick clobber sanity check
    if !(@options[:clobber] || @options[:profiles_only])
      err = []

      if @processor.needs_to_clobber?
        err << "[XXX] Application directory already exists."
      end
      if @profiles.needs_to_clobber?
        err << "[XXX] Chromium profile directory already exists."
      end

      err << "\tUse -c to reinstall, or -P to regenerate profiles only." if err.size > 0

      abort err.join("\n") if err.size > 0
    end

    # throw an error if Chrome is currently running
    pid = @profiles.current_chromium_pid
    if pid
      abort "[XXX] Chromium is already running as PID #{pid}.\n\tQuit Chromium before installing."
    end
  end

  def global_launch_instructions
    # Make sure the CRM-114 is working first

    puts "
Click on the \"Getting Started\" bookmark after launching Chromium."
  end
end
