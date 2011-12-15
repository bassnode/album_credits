# -*- encoding: utf-8 -*-
$:.unshift File.join(File.dirname(__FILE__), 'lib')
require "album_credits/version"

Gem::Specification.new do |s|
  s.name        = "album_credits"
  s.version     = AlbumCredits::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["bassnode"]
  s.email       = ["bassnode@gmail.com"]
  s.homepage    = "https://github.com/bassnode/album_credits"
  s.summary     = %q{Provides album engineering credits}
  s.description = %q{Searches databases for a given artist + album combination and returns recording engineering information.}

  s.rubyforge_project = "album_credits"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "discogs-wrapper"
  s.add_development_dependency "ruby-debug"
end
