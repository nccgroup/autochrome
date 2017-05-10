require_relative '../fake_json'
require_relative '../fetch_cr'
require 'openssl'

class Prefs
  attr_reader :data

  def initialize(data = {})
    @data = data
  end

  def []= (key,value)
    path = key.split(".").map &:to_sym
    leaf_key = path.pop
    obj = @data
    path.each do |k|
      #TODO do we need to allow arrays?
      #XXX need checks for trying to traverse into existing non-objects
      obj[k] ||= {};
      obj = obj[k]
    end
    obj[leaf_key] = value
  end

  def to_json
    @data.to_json
  end
end

class SecurePrefs < Prefs
  # Chromium "secures" prefs against tampering with HMAC-SHA256.
  # I *think* this is just on MacOS (and Windows), not Linux.
  # The HMACed message is three concatenated values: a device uuid, the key
  # path, and the serialized value.
  
  # serialized value does some special case processing to strip empty arrays...?

  # Called "seed" in the Chromium code base; appears to only be set for Google
  # Chrome builds.
  HMAC_KEY = ''

  def uuid
    @uuid ||= @opts[:uuid] || case @opts[:os_type]
    when 'Mac'
      if FetchCr.guess_type != 'Mac'
        raise "can't determine UUID for MacOS secure prefs when not on a Mac"
      end
      s = `ioreg -rd1 -c IOPlatformExpertDevice`
      m = s.match(/"IOPlatformUUID" = "([A-F0-9-]+)"/)
      if m then m[1] else raise "failed to determine MacOS UUID with ioreg" end
    when /^Linux/
      ''
    else
      raise "Missing or unexpected OS: #{@opts[:os_type].inspect}"
  end
  end

  def initialize(data, opts)
    raise "initial data for secure prefs not supported" unless data.nil? or data.empty?
    super()
    @opts = opts
    @sigs = Prefs.new
  end

  def []=(key, value)
    value = normalize(value)
    super
    @sigs[key] = sign(key, value)
  end

  def normalize(value)
    if value.is_a? Hash
      value.sort.map { |k,v| [k, normalize(v)] }.to_h
    else
      value
    end
  end

  def sign(key, value)
    message = uuid + key + serialize(value)
    hmac = OpenSSL::HMAC.new(HMAC_KEY, OpenSSL::Digest::SHA256.new)
    hmac << message
    hmac.hexdigest.upcase
  end

  # Values are serialized as minimal JSON.  We gloss over a couple of details
  # here:  I'm assuming the values are always in alphabetical order. Floating
  # point numbers are always formatted with a decimal. Chromium also trims
  # empty object and array values, which we don't do.  (TODO?)
  def serialize(value)
    value.to_json
  end

  def to_json
    data.dup.merge({ protection: { macs: @sigs.data } }).to_json
  end
end
