$:.unshift File.expand_path(File.dirname(__FILE__))

require 'neverblock'
#socket and file will require IO.rb in core
require 'neverblock/io/socket'
require 'neverblock/io/file'
