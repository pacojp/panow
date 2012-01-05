$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

# HACKME ここで呼ぶのか？
require 'active_support/all'

require 'panow/html_parser'
require 'panow/extract_content'


module Panow
  VERSION = '0.0.1'
end
