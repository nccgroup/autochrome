require_relative '../processor'

class ChromeProcessor
  def unpack(file)
    raise NotImplementedError
  end

  def tweak_install(file)
    raise NotImplementedError
  end

  def install
    if !@extdir
      raise "Need to unpack first"
    end

    if @clobber
      if File.exists? @installdir
        FileUtils.remove_entry_secure(@installdir)
      end
    elsif needs_to_clobber?
      raise "Not clobbering existing file"
    end

    FileUtils.mkdir_p(File.dirname(@installdir))

    FileUtils.move(@extdir, @installdir)
    @extdir = nil

    puts "[---] Installed Chromium"
  end

  def cleanup
    if @tmpdir && File.exists?(@tmpdir)
      FileUtils.remove_entry_secure(@tmpdir)
      @tmpdir = nil
    end
  end

  def needs_to_clobber?
    File.exists? @installdir
  end

  def self.new_from_type(opts={})
    case opts[:os_type]
    when "Mac"
      ChromeProcessor::MacOSX.new(opts)
    when "Linux_x64"
      ChromeProcessor::Linux.new(opts)
    else
      raise NotImplementedError
    end
  end

  def launch_instructions
    raise NotImplementedError
  end
end
