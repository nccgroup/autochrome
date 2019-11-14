require "digest"
require "json"
require "open3"

class AutoChrome::ChromeExtension
  attr_reader :path, :id, :key, :manifest, :version
  def initialize(crx_path)
    @path = crx_path

    data = File.read(@path, mode: 'rb')
    key_file = File.dirname(path) + "/" + File.basename(@path, ".crx") + ".pub"
    if !File.exists?(key_file)
      raise "No key file found for extension #{path}"
    end
    @key = File.read(key_file)
    @id = Digest::SHA256.hexdigest(key)[0...32].tr('0-9a-f', 'a-p')

    # use open3 to suppress unzip warnings for unexpected crx headers
    json, _, _ = Open3.capture3('unzip', '-qc', @path, 'manifest.json')

    @manifest = JSON.parse(json, symbolize_names: true)
    @manifest[:key] = Base64.encode64(@key).gsub(/\s/, '')

    @version = @manifest[:version]
  end
end
