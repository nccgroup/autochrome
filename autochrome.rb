#!/usr/bin/env ruby

require 'rubygems'
if Gem::Version.new('1.9') > Gem::Version.new(RUBY_VERSION)
  puts "Your version of Ruby (#{RUBY_VERSION}) is too old.
Please upgrade to the latest version of Ruby."
  exit 1
end

require_relative 'lib/autochrome'

a = AutoChrome.new(ARGV)
a.go
