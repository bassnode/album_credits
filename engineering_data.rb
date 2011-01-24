require 'rubygems'
#require 'ap'
require 'discogs'
require 'cgi'
require 'ruby-debug'

def parse_discogs_id(search_result)
  search_result.uri.split('/').last
end

def discogs
  Discogs::Wrapper.new("bff9085fc7")
end

def find_releases(artist, album)
  releases = []
  [nil, 'CD', 'HDCD', 'vinyl'].each do |format|
    format = " AND format:#{format}" if format
    query = CGI.escape("#{album} AND artist:#{artist}#{format}")
    possibilities = discogs.search(query)
    if possibilities.searchresults.size > 0
      possibilities.searchresults.each do |found_album|
        # puts "trying #{found_album.inspect}"
        release = discogs.get_release(parse_discogs_id(found_album))
        # Make sure the album is actually what we think it is and that it
        # is in an Accepted state (as per Discogs).
        if release.title =~ /#{album}/i && release.status == 'Accepted'
          releases << release
        end
      end
    else
      puts "no results for #{query}"
    end
  end
  releases
end

def engineers_for_release(release)
  if release.extraartists && !(engineers = release.extraartists.select{|a| a.role =~ /mix|master|engineer/i}).empty?
    return engineers
  end
end

def image_uri_for_release(release)
  return if release.images.nil?
  img = release.images.detect{|i| i.type == 'primary'}
  img = release.images.detect{|i| i.type == 'secondary'} if img.nil?
  img.uri if img
end

artist = ARGV[0]
album = ARGV[1]
releases = find_releases(artist, album)
puts "Found #{releases.size} releases"

releases.each do |release|
  puts 
  puts "="*40
  puts "#{release.title} #{release.released} ID: #{release.id}"
  puts release.notes
  puts image_uri_for_release(release)
  puts "#{release.tracklist.size} songs"

  engineers = engineers_for_release(release)
  unless engineers.nil?
    puts release.title
    engineers.each do |engineer|
      # discogs.get_artists(engineer)
      p "#{engineer.role} #{engineer.name}"
      # Then show some cross-section of their work.
      # maybe start with around the year that current album was released if there are many.
      # otherwise, just chron. order
    end
  end
end unless releases.empty?


