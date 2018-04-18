#!/usr/bin/env ruby

require 'crxmake'
require 'json'
require 'fileutils'

DATA_DIR = File.expand_path("../data", __FILE__)

THEME_COLORS = {
  Cyan: 0.5,
  Blue: 0.61,
  Green: 0.28,
  Orange: 0.08,
  Purple: 0.79,
  Red: 1.0,
  Yellow: 0.164,
  White: -1.0,
}

THEME_IMAGE = 'caution.png'
THEME_IMAGE_PATH = File.join(DATA_DIR,'theme_source',THEME_IMAGE)
THEME_OUTPUT_PATH = File.join(DATA_DIR, 'themes')

EXT_SOURCE_DIR = File.join(DATA_DIR, 'extension_source')
EXT_OUTPUT_DIR = File.join(DATA_DIR, 'extensions')

# Build themes

THEME_COLORS.each do |color_name,hue|
  Dir.mktmpdir do |temp_dir|
    manifest_path = File.join(temp_dir,'manifest.json')
    File.write(manifest_path, JSON.generate({
      name: "Caution #{color_name}",
      version: '1.1',
      manifest_version: 2,
      theme: {
        images: {
          theme_frame: THEME_IMAGE,
          theme_frame_inactive: THEME_IMAGE
        },
        tints: {
          background_tab: [-1.0, -1.0, 0.95],
          frame:                    [hue, -1.0, -1.0],
          frame_inactive:           [hue, -1.0, 0.7],
          frame_incognito:          [hue, 0.2, -1.0],
          frame_incognito_inactive: [hue, 0.2, 0.7]
        }
      }
    }))

    FileUtils.cp(THEME_IMAGE_PATH, temp_dir)
    CrxMake.make(
      ex_dir: temp_dir,
      pkey_output: '/dev/null', #generate key, but don't bother to store it
      crx_output: File.join(THEME_OUTPUT_PATH, "#{color_name}.crx")
    )
  end
end

# Build extensions

Dir.each_child(EXT_SOURCE_DIR) do |ext|
  CrxMake.make(
    ex_dir: File.join(EXT_SOURCE_DIR, ext),
    pkey_output: '/dev/null',
    crx_output: File.join(EXT_OUTPUT_DIR, "#{ext}.crx")
  )
end

