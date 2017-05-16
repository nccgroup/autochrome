#!/usr/bin/env/ruby
require 'Base64'

html = File.read('index.html')
html.gsub! /(?<=<img src=")[^"]+(?=")/ do |src|
  b64 = Base64.strict_encode64(File.read(src)).chomp
  "data:image/png;base64,#{b64}"
end
puts html
