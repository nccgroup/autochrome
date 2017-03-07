require "digest"
require "json"
require "open3"

module CrExt
  def self.get_crx_key(crx)
    data = open(crx, "rb") {|f| f.read}
    sig, ver, keylen, _ = data[0...16].unpack("A4LLL")
    key = data[16...16+keylen].unpack("A%d" % [keylen]).first
  end

  def self.calculate_crx_id(key)
    hash = Digest::SHA256.hexdigest(key)
    crxhash = hash[0...32].tr("0-9a-f","a-q")
  end

  def self.get_crx_manifest(crx)
    # XXX Linux and OS X specific
    manifest = Open3.popen3("unzip", "-qc", crx, "manifest.json") do |i,o|
      o.read
    end
    JSON.parse(manifest)
  end

  def self.get_crx_version(crx)
    manifest = get_crx_manifest(crx)
    manifest["version"]
  end
end
