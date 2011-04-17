require 'rubygems'
require 'cgi'
require 'discogs'
require 'album_credits/exceptions'
require 'album_credits/core_ext'
require 'album_credits/display'
require 'album_credits/finder'

begin; require 'ruby-debug'; rescue LoadError; end
