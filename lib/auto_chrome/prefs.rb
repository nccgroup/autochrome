require 'openssl'

require_relative 'fetcher' #for actual OS type (can't gen mac prefs on non-mac)

class AutoChrome
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

    def to_json(opt={})
      @data.to_json(opt)
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
        if AutoChrome::Fetcher.guess_type != 'Mac'
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

    # alphabetical sorting; see also serialize
    def normalize(value)
      if value.is_a? Hash
        Hash[value.sort.map { |k,v| [k, normalize(v)] }]
      else
        value
      end
    end

    def super_mac
      sign('', normalize(@sigs.data))
    end

    def sign(key, value)
      message = uuid + key + serialize(value)
      hmac = OpenSSL::HMAC.new(HMAC_KEY, OpenSSL::Digest::SHA256.new)
      hmac << message
      hmac.hexdigest.upcase
    end


    # Values are serialized for signing as minimal JSON with some quirks:
    #
    # - Chrome recursively ignores empty arrays and objects.  This is not
    #   implemented, so avoid those.
    # - Chrome outputs null values as the empty string.  There's code for that,
    #   but it's untested.  (XXX- maybe not true, based on expected output in pref_hash_calculator.unittest)
    # - I'm also unclear on if ordering is always alphabetical; we do that on
    #   insert (see the call to normalize), which seems to work.
    #
    # see ValueAsString in Chromium's pref_hash_calculator.cc
    #
    # see kTrackedPrefs in chrome_pref_service_factory.cc, and Settings.TrackedPreference* in chrome:histograms
    # for debugging
    def serialize(value)
      return '' if value.nil?
      value.to_json
    end

    def to_json(opt={})
      data.dup.merge({ protection: { macs: @sigs.data, super_mac: super_mac } }).to_json(opt)
    end
  end
end
