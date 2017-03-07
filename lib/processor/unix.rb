require_relative '../processor'

require 'fileutils'
require 'tmpdir'
require 'open3'

class ChromeProcessor::UNIX < ChromeProcessor
  def initialize(opts={})
    to = File.expand_path(opts[:install_dir] || self.class::DefaultFilesystemLocation)
    @installdir = File.expand_path(self.class::FinalAppName, to)
    @profiledir = opts[:data_dir]
    @clobber = opts[:clobber]
    @proxyport = opts[:proxybase] || 8080
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
