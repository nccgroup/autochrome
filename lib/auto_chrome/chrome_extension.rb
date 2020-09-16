require "digest"
require "json"
require "open3"

class AutoChrome::ChromeExtension
  attr_reader :path, :id, :key, :manifest, :version

  def initialize(crx_path)
    @path = crx_path

    # use open3 to suppress unzip warnings for unexpected crx headers
    json, _, _ = Open3.capture3('unzip', '-qc', @path, 'manifest.json')

    @manifest = JSON.parse(json, symbolize_names: true)

    key_file = File.dirname(path) + "/" + File.basename(@path, ".crx") + ".pub"
    if !File.exist?(key_file)
      if @manifest.dig(:key) != nil
        puts "[---] Reading key from manifest, this might not work..."
        @key = @manifest[:key]
        @id = Digest::SHA256.hexdigest(Base64.decode64(@key))[0...32].tr('0-9a-f', 'a-p')
      else
        raise "No key file or key in manifest found for extension #{path}"
      end
    else
      @key = File.read(key_file)
      @id = Digest::SHA256.hexdigest(key)[0...32].tr('0-9a-f', 'a-p')
      @manifest[:key] = Base64.encode64(@key).gsub(/\s/, '')
    end

    if @manifest.dig(:id) != nil
      @id = @manifest[:id]
    else
      if :id == nil || id.to_s.strip.empty?
        raise "No id found for extension #{path}!"
      end
    end

    if @manifest.dig(:version) != nil
      @version = @manifest[:version]
    else
      if :version == nil
        raise "No version found for extension #{path}!"
      end
    end
  end
end
