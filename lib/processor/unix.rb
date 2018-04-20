require_relative '../processor'

require 'fileutils'
require 'tmpdir'
require 'open3'

class ChromeProcessor::UNIX < ChromeProcessor
  def initialize(opts={})
    sanity_check

    to = File.expand_path(opts[:install_dir] || self.class::DefaultFilesystemLocation)
    @installdir = File.expand_path(self.class::FinalAppName, to)
    @profiledir = opts[:data_dir]
    @clobber = opts[:clobber]
    @proxyhost = opts[:proxyhost] || 'localhost'
    @proxyport = opts[:proxybase] || 8080
  end

  def sanity_check
    if Process.uid == 0
      STDERR.puts "[!!!] WARNING: You are running autochrome as root."
      STDERR.puts "[!!!] Running Chromium as root will disable the sandbox."
    end
  end

  def unpack(file)
    begin
      @tmpdir = Dir.mktmpdir
      FileUtils.mkdir_p(File.expand_path(@tmpdir))

      Open3.popen3("unzip", "-d", @tmpdir, file.path, "#{self.class::ZipAppLocation}/*") do |stdin, stdout, stderr|
        stdout.read
      end

      @extdir = File.expand_path(self.class::ZipAppLocation, @tmpdir)
    ensure
      file.close
    end
  end
end
