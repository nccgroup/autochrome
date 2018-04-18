require 'fileutils'
require 'pp'

require_relative 'chromecache'
require_relative 'processor'

class AutoChrome
  require_relative 'auto_chrome/profile_builder'
  require_relative 'auto_chrome/fetcher'

  DATA_BASE_DIR = File.expand_path("../data", File.dirname(__FILE__))

  def check_type(type)
    Fetcher::TypeZipMap.key? type
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

    c = Fetcher.new(opts[:os_type])
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


  def go
    unless @options[:profiles_only]
      crfile, version = get_chrome(@options)
      @processor.unpack(crfile)
      @processor.tweak_install
      @processor.install
    end

    @profile_builder.generate
    @profile_builder.add_extensions
    @profile_builder.add_themes
    @profile_builder.install

    unless @options[:profiles_only]
      @processor.launch_instructions
      global_launch_instructions
    end
  ensure
    unless @options[:profiles_only]
      @processor.cleanup
    end
    @profile_builder.cleanup
  end
  
  def current_chromium_pid
    process = File.expand_path("SingletonLock", @options[:data_dir])
    if File.symlink?(process)
      pid = File.readlink(process).split("-")[1]
      if pid.to_i == 0
        pid = "unknown"
      end
    end

    pid
  end

  def initialize(opts)
    raise "bad opts" unless opts.is_a? Hash
    @options = opts

    # type must be set before doing useful things
    type = @options[:os_type] || Fetcher.guess_type
    if !check_type(type)
      if @options[:os_type]
        puts "[XXX] The type specified was #{@options[:os_type]}."
      else
        puts "[XXX] Your operating system couldn't be determined!"
      end
      abort "[XXX] OS type needs to be one of #{Fetcher::TypeZipMap.keys.join(" / ")}."
    end
    @options[:os_type] = type
    @options[:data_dir] ||= ProfileBuilder.get_default_directory(type)

    unless @options[:profiles_only]
      @processor = ChromeProcessor.new_from_type(@options)
      if !@processor
        abort "[XXX] Unable to create processor"
      end
    end

    @profile_builder = ProfileBuilder.new(@options)

    # do a quick clobber sanity check
    if !(@options[:clobber] || @options[:profiles_only])
      err = []

      if @processor.needs_to_clobber?
        err << "[XXX] Application directory already exists."
      end
      if @profile_builder.needs_to_clobber?
        err << "[XXX] Chromium profile directory already exists."
      end

      err << "\tUse -c to reinstall, or -P to regenerate profiles only." if err.size > 0

      abort err.join("\n") if err.size > 0
    end

    # throw an error if Chrome is currently running
    if pid = current_chromium_pid
      abort "[XXX] Chromium is already running as PID #{pid}.\n\tQuit Chromium before installing."
    end
  end

  def global_launch_instructions
    # Make sure the CRM-114 is working first

    puts "
Click on the \"Getting Started\" bookmark after launching Chromium."
  end
end
