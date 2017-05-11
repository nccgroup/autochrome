#!/usr/bin/env ruby

if RUBY_VERSION < '1.9'
  STDERR.puts "Your version of ruby (#{RUBY_VERSION}) is crazy old, and autochrome definitely will not work; sorry."
  exit 1
elsif
  RUBY_VERSION < '2.3'
  STDERR.puts "Your version of ruby (#{RUBY_VERSION}) is a bit old.  Attempting to continue anyway..."
end

$: << File.join(File.dirname(__FILE__), 'lib')
require 'auto_chrome'

a = AutoChrome.new(ARGV)
a.go
