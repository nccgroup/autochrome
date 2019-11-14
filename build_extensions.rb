#!/usr/bin/env ruby

require 'json'
require 'fileutils'
require 'tmpdir'
require 'optparse'
require 'open3'
require 'digest'

DATA_DIR = File.expand_path("../data", __FILE__)

THEME_COLORS = {
  Cyan: 0.5,
  Blue: 0.61,
  Green: 0.28,
  Orange: 0.08,
  Purple: 0.79,
  Red: 1.0,
  Yellow: 0.164,
  White: 0.0,
}

THEME_IMAGE = 'caution.png'
THEME_IMAGE_PATH = File.join(DATA_DIR,'theme_source',THEME_IMAGE)
THEME_OUTPUT_PATH = File.join(DATA_DIR, 'themes')

EXT_SOURCE_DIR = File.join(DATA_DIR, 'extension_source')
EXT_OUTPUT_DIR = File.join(DATA_DIR, 'extensions')


def parse_options(arg_list)
  options = { path: "~/Applications/Chromium.app/Contents/MacOS/Chromium-orig" }

  OptionParser.new do |opts|
    opts.banner = "Usage: #{File.basename($0)} [options]"
    opts.separator ""

    opts.on("-p", "--path Chromium Path", "Path to chromium-orig") do |t|
      options[:path] = t
    end
    opts.on("-h", "--help", "Show this message") do
      puts opts
      exit 1
    end
  end.order(arg_list)

  options
end


options = parse_options(ARGV)

if !File.exists?(File.expand_path(options[:path]))
  puts "Chromium at #{options[:path]} does not exist. Specify location with --path"
  exit 1
end

def build_extension(options, path, target)
  system("#{options[:path]} --no-sandbox -no-message-box --pack-extension=#{path}")
  pubkey, _, _ = Open3.capture3('openssl', 'rsa', '-in', "#{path}.pem", '-pubout', '-outform', 'DER')
  File.write("#{File.dirname(target)}/#{File.basename(target, ".crx")}.pub", pubkey)
  FileUtils.mv("#{path}.crx", target)
  FileUtils.rm("#{path}.pem")
end

# Build themes

THEME_COLORS.each do |color_name,hue|
  Dir.mktmpdir do |temp_dir|
    manifest_path = File.join(temp_dir,'manifest.json')
    File.write(manifest_path, JSON.generate({
      "name": "Caution #{color_name}",
      "version": "1.1",
      "manifest_version": 2,
      "theme": {
        "images": {
          "theme_frame": "#{THEME_IMAGE}",
          "theme_frame_inactive": "#{THEME_IMAGE}"
        },
        "tints": {
          "background_tab": [-1.0, -1.0, 0.95],
          "frame":                    [hue, hue == 0 ? 0 : -1.0, -1.0],
          "frame_inactive":           [hue, hue == 0 ? 0 : -1.0, 0.7],
          "frame_incognito":          [hue, hue == 0 ? 0 : -1.0, -1.0],
          "frame_incognito_inactive": [hue, hue == 0 ? 0 : -1.0, 0.7]
        }
      }
    }))

    FileUtils.cp(THEME_IMAGE_PATH, temp_dir)
    build_extension(options, temp_dir, "#{THEME_OUTPUT_PATH}/#{color_name}.crx")
  end
end

# Build extensions
exts = ['autochrome_junk_drawer', 'settingsreset']
exts.each do |ext|
  build_extension(options, "#{EXT_SOURCE_DIR}/#{ext}", "#{EXT_OUTPUT_DIR}/#{ext}.crx")
end

