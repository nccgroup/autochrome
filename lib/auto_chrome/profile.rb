require 'fileutils'
require 'tmpdir'
require_relative '../chrome_extension'
require 'securerandom'
require 'base64'

require 'auto_chrome/prefs'

IconColors = {
  "White"  => "chrome://theme/IDR_PROFILE_AVATAR_0",
  "Cyan"   => "chrome://theme/IDR_PROFILE_AVATAR_1",
  "Blue"   => "chrome://theme/IDR_PROFILE_AVATAR_2",
  "Green"  => "chrome://theme/IDR_PROFILE_AVATAR_3",
  "Orange" => "chrome://theme/IDR_PROFILE_AVATAR_4",
  "Purple" => "chrome://theme/IDR_PROFILE_AVATAR_5",
  "Red"    => "chrome://theme/IDR_PROFILE_AVATAR_6",
  "Yellow" => "chrome://theme/IDR_PROFILE_AVATAR_7",
}

class AutoChrome::Profile

  attr_reader :secure_prefs
  def initialize(opts={})
    @opts = opts
    @dirname = opts[:dirname] || SecureRandom.hex
    init_prefs
  end

  def generate
    @tmpdir = Dir.mktmpdir
    FileUtils.mkdir_p(File.expand_path(@tmpdir))

    # broken for now
    # remove_all_search_engines
  end

  def profile_entry
    hash = {
      "name" => @dirname,
    }
    if IconColors.keys.include? @dirname
      hash["avatar_icon"] = IconColors[@dirname]
    end
    [@dirname, hash]
  end

  def install(dir)
    write_preferences
    write_bookmarks

    if !File.exists?(dir)
      raise "Need valid installation directory"
    end

    FileUtils.move(@tmpdir, File.join(dir, @dirname))

    cleanup
  end

  def cleanup
    if @tmpdir && File.exists?(@tmpdir)
      FileUtils.remove_entry_secure(@tmpdir)
      @tmpdir = nil
    end
  end

  def set_theme(crx)
    @prefs['extensions.theme'] = { id: crx.id }
  end

  private

  def init_prefs
    @prefs = AutoChrome::Prefs.new({
      "alternate_error_pages" => {
        "enabled" => false,
      },
      "autofill" => {
        "enabled" => false,
      },
      "bookmark_bar" => {
        "show_apps_shortcut" => false,
      },
      "browser" => {
        # 2099 in windows time format
        default_browser_infobar_last_declined: 157154112000000000,

        # clears everything that is not a URL in the history or cached files
        "clear_data" => {
          "browsing_history" => false,
          "cache" => false,
          "download_history" => false,
          "form_data" => true,
          "hosted_apps_data" => true,
          "passwords" => true,
          "time_period" => 4,
        },
      },
      "default_search_provider_data" => {
        "template_url_data" => {
          "keyword" => "null",
          "short_name" => "Null",
          "url" => 'about:version#{searchTerms}',
        },
      },
      "dns_prefetching" => {
        "enabled" => false,
      },
      "download" => {
        "prompt_for_download" => true,
      },
      "ntp" => {
        # kills Welcome to Chromium and Chrome Web Store links
        "most_visited_blacklist" => {
          "c8e0afd1da1d9e29511240861f795a5a" => nil,
          "eacc8c3ad0b50bd698ef8752d5ee24b6" => nil,
        },
      },
      "profile" => {
        "password_manager_enabled" => false,
        "default_content_settings" => {
          "plugins" => 3, # click-to-play
        },
      },
      "safebrowsing" => {
        "enabled" => false,

        # just in case; not actually sure what these do
        extended_reporting_enabled: false,
        scout_reporting_enabled: false,
      },
      "search" => {
        "suggest_enabled" => false,
      },
      "translate" => {
        "enabled" => false,
      },
    })

    @secure_prefs = AutoChrome::SecurePrefs.new(nil, @opts)
  end

  def write_preferences
    f = open(File.join(@tmpdir, "Preferences"), "w")
    f.write @prefs.to_json
    f.close

    f = open(File.join(@tmpdir, "Secure Preferences"), "w")
    f.write @secure_prefs.to_json
    f.close
  end

  def write_bookmarks
    if !@tmpdir
      raise "No temporary directory"
    end

    obj = {
      "roots" => {
        "bookmark_bar" => {
          "children" => [
            {
              "name" => "Getting Started",
              "type" => "url",
              "url" => "chrome-extension://dlbddhjpellkabmnjehhcngjokkibbcg/startpage/index.html",
            },
            {
              "name" => "Burp History",
              "type" => "url",
              "url" => "http://burp/history",
            },
            {
              "name" => "Burp CA Certificate",
              "type" => "url",
              "url" => "http://burp/cert",
            },
          ],
          "type" => "folder",
        },
        "other" => {
          "children" => [
            {
              "name" => "Autochrome Profile Name",
              "type" => "url",
              "url" => "http://#{@dirname.gsub(/[^0-9a-zA-Z]/, "")}",
            },
          ],
          "type" => "folder",
        },
      },
      "version" => 1,
    }

    f = open(File.join(@tmpdir, "Bookmarks"), "w")
    f.write obj.to_json
    f.close
  end

  def remove_all_search_engines
    if !@tmpdir
      raise "No temporary directory"
    end

    # These entries are just here to prevent Chrome from squawking about
    # missing stuff while still having created the table that contains
    # all of the search providers. They serve no other purpose.

    statements = <<-EOS
BEGIN TRANSACTION;
CREATE TABLE meta(key LONGVARCHAR NOT NULL UNIQUE PRIMARY KEY, value LONGVARCHAR);
INSERT INTO "meta" VALUES('version','70');
INSERT INTO "meta" VALUES('last_compatible_version','70');
INSERT INTO "meta" VALUES('Builtin Keyword Version','97');
INSERT INTO "meta" VALUES('mmap_status','-1');
CREATE TABLE keywords (id INTEGER PRIMARY KEY,short_name VARCHAR NOT NULL,keyword VARCHAR NOT NULL,favicon_url VARCHAR NOT NULL,url VARCHAR NOT NULL,safe_for_autoreplace INTEGER,originating_url VARCHAR,date_created INTEGER DEFAULT 0,usage_count INTEGER DEFAULT 0,input_encodings VARCHAR,suggest_url VARCHAR,prepopulate_id INTEGER DEFAULT 0,created_by_policy INTEGER DEFAULT 0,instant_url VARCHAR,last_modified INTEGER DEFAULT 0,sync_guid VARCHAR,alternate_urls VARCHAR,search_terms_replacement_key VARCHAR,image_url VARCHAR,search_url_post_params VARCHAR,suggest_url_post_params VARCHAR,instant_url_post_params VARCHAR,image_url_post_params VARCHAR,new_tab_url VARCHAR, last_visited INTEGER DEFAULT 0);
CREATE TABLE autofill_profile_names ( guid VARCHAR, first_name VARCHAR, middle_name VARCHAR, last_name VARCHAR);
CREATE TABLE autofill_profiles ( guid VARCHAR PRIMARY KEY, company_name VARCHAR, address_line_1 VARCHAR, address_line_2 VARCHAR, city VARCHAR, state VARCHAR, zipcode VARCHAR, country VARCHAR, country_code VARCHAR, date_modified INTEGER NOT NULL DEFAULT 0);
CREATE TABLE credit_cards ( guid VARCHAR PRIMARY KEY, name_on_card VARCHAR, expiration_month INTEGER, expiration_year INTEGER, card_number_encrypted BLOB, date_modified INTEGER NOT NULL DEFAULT 0, origin VARCHAR DEFAULT '', use_count INTEGER NOT NULL DEFAULT 0, use_date INTEGER NOT NULL DEFAULT 0);
CREATE TABLE token_service (service VARCHAR PRIMARY KEY NOT NULL,encrypted_token BLOB);
CREATE TABLE autofill (name VARCHAR, value VARCHAR, value_lower VARCHAR, date_created INTEGER DEFAULT 0, date_last_used INTEGER DEFAULT 0, count INTEGER DEFAULT 1, PRIMARY KEY (name, value));
CREATE TABLE autofill_profile_emails ( guid VARCHAR, email VARCHAR);
CREATE TABLE autofill_profile_phones ( guid VARCHAR, number VARCHAR);
CREATE TABLE autofill_profiles_trash ( guid VARCHAR);
CREATE TABLE masked_credit_cards (id VARCHAR,status VARCHAR,name_on_card VARCHAR,type VARCHAR,last_four VARCHAR,exp_month INTEGER DEFAULT 0,exp_year INTEGER DEFAULT 0);
CREATE TABLE unmasked_credit_cards (id VARCHAR,card_number_encrypted VARCHAR, use_count INTEGER NOT NULL DEFAULT 0, use_date INTEGER NOT NULL DEFAULT 0, unmask_date INTEGER NOT NULL DEFAULT 0);
CREATE TABLE server_card_metadata (id VARCHAR NOT NULL,use_count INTEGER NOT NULL DEFAULT 0, use_date INTEGER NOT NULL DEFAULT 0, billing_address_id VARCHAR);
CREATE TABLE server_addresses (id VARCHAR,company_name VARCHAR,street_address VARCHAR,address_1 VARCHAR,address_2 VARCHAR,address_3 VARCHAR,address_4 VARCHAR,postal_code VARCHAR,sorting_code VARCHAR,country_code VARCHAR,language_code VARCHAR, recipient_name VARCHAR, phone_number VARCHAR);
CREATE TABLE server_address_metadata (id VARCHAR NOT NULL,use_count INTEGER NOT NULL DEFAULT 0, use_date INTEGER NOT NULL DEFAULT 0, has_converted BOOL NOT NULL DEFAULT FALSE);
CREATE TABLE autofill_sync_metadata (storage_key VARCHAR PRIMARY KEY NOT NULL,value BLOB);
CREATE TABLE autofill_model_type_state (id INTEGER PRIMARY KEY, value BLOB);
CREATE INDEX autofill_name ON autofill (name);
CREATE INDEX autofill_name_value_lower ON autofill (name, value_lower);
COMMIT;
    EOS

    Open3.popen3("sqlite3", "-batch", File.join(@tmpdir, "Web Data")) do |stdin, stdout, stderr|
      stdin.write(statements)
      stdin.close
      stdout.read
    end
  end

  #not used
  def add_unpacked_extension(crx)
    if !@tmpdir
      raise "No temporary directory"
    end

    extract_dir = File.join(@tmpdir, "Extensions", crx.id, crx.version)
    FileUtils.mkdir_p(extract_dir)

    # use open3 to suppress unzip warnings for unexpected crx headers
    Open3.capture3("unzip", "-d", extract_dir, crx.path)

    @secure_prefs["extensions.settings.#{crx.id}"] = {
      manifest: crx.manifest,

    }

    return extract_dir
  end

end
