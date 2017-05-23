require "digest"
require "json"
require "open3"

class AutoChrome::ChromeExtension
  attr_reader :path, :id, :key, :manifest, :version
  def initialize(crx_path)
    @path = crx_path

    data = File.read(@path, mode: 'rb')
    sig, ver, keylen, _ = data[0...16].unpack("A4LLL")
    @key = data[16...16+keylen].unpack("A%d" % [keylen]).first
    @id = Digest::SHA256.hexdigest(key)[0...32].tr('0-9a-f', 'a-q')

    # use open3 to suppress unzip warnings for unexpected crx headers
    json, _, _ = Open3.capture3('unzip', '-qc', @path, 'manifest.json')

    @manifest = JSON.parse(json, symbolize_names: true)
    @manifest[:key] = Base64.encode64(@key).gsub(/\s/, '')

    @version = @manifest[:version]
  end
end
