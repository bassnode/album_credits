require 'rubygems'
#require 'ap'
require 'discogs'
require 'cgi'
require 'ruby-debug'
COLORS = {
  :clear => "\e[0m",
  :bold => "\e[1m",
  :black => "\e[30m",
  :white => "\e[37m",
  :red   => "\e[31m",
  :green => "\e[32m",
  :yellow => "\e[33m",
  :blue => "\e[34m"
}

def color_puts(text, color, bold=false)
  embolden = bold ? COLORS[:bold] : ''
  puts "#{embolden}#{COLORS[color]}#{text}#{COLORS[:clear]}"
end

def parse_discogs_id(search_result)
  search_result.uri.split('/').last
end

def discogs
  return @discogs if @discogs
  @discogs = Discogs::Wrapper.new("bff9085fc7")
end

def find_releases(artist, album, year=nil)
  releases = []
  [nil, 'CD', 'HDCD', 'vinyl'].each do |format|
    format = " AND format:#{format}" if format
    query = CGI.escape("#{album} AND artist:#{artist}#{format}")
    possibilities = discogs.search(query, 'releases')
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
      # puts "no results for #{query}"
    end
  end

  # Could put this later but still trying to figure out if we want to narrow
  # by year if it removes all potential results.
  releases.reject!{ |r| r.released.to_s.split('-').first.to_s != year } if year

  # Only return unique releases
  seen = {}
  uniq_releases = releases.inject([]) do |uniq, rel|
    unless seen.has_key?(rel.id)
      seen[rel.id] = 1
      uniq << rel
    end
    uniq
  end

  # Only return with nil release date filter unless it filters out everything.
  pristine_releases = uniq_releases.reject{|release| release.released.nil?}
  pristine_releases.size < uniq_releases.size ? pristine_releases : uniq_releases
end

def engineers_for_release(release)
  if release.extraartists && !(engineers = release.extraartists.select{|a| a.role =~ /mix|master|engineer/i}).empty?
    return engineers
  end
end

def discography_for_artist(artist)
  debugger
  discogs.get_artist(CGI.escape(artist)) rescue []
end

def image_uri_for_release(release)
  return if release.images.nil?
  img = release.images.detect{|i| i.type == 'primary'}
  img = release.images.detect{|i| i.type == 'secondary'} if img.nil?
  img.uri if img
end

def display_release(release, engineers, options={})
  color = options.delete(:color) || :white
  show_discography = options[:show_discography] == true

  color_puts "="*40, color
  color_puts "#{release.title} #{release.released} ID: #{release.id}", color
  color_puts "#{release.tracklist.size} songs", color
  color_puts image_uri_for_release(release), color
  color_puts release.notes, color
  color_puts "Engineers:", color
  engineers.each do |engineer|
    color_puts "#{engineer.role} #{engineer.name}", color, true
    # Print the first 100 releases in the engineer's discography
    if show_discography && !(artist = discogs.get_artist(CGI.escape(engineer.name))).nil?
      color_puts "#{artist.aliases} #{artist.aliases} #{artist.namevariations}", color
      color_puts "#{artist.releases.size} releases in discography"
      artist.releases.slice(0,99).each do |disk|
        color_puts "\t* #{disk.year} #{disk.title} [#{disk.label}]", color
      end
      # IDEA: show a cross-section of their work.
      # maybe start with around the year that current album was released if there are many.
      # ALSO: could filter their discog. output by x-ref w/ the role they
      # played on this album. e.g. only show Bob Ludwig's mastering work, not
      # mixing.  Could be ugly b/c I'll have to pull down every release
      # individually.
    end
  end
end


artist = ARGV[0]
album = ARGV[1]
year = ARGV[2]
releases = find_releases(artist, album, year)
raise "No releases" if releases.empty?
puts "Found #{releases.size} releases"

sorted_releases = releases.inject([]) do |rel_array, release|
  unless (engineers = engineers_for_release(release)).nil?
    rel_array << [release, engineers]
  end
  rel_array
end.sort_by{|arr| arr.last.size}.reverse

raise "No engineering data though :/" if sorted_releases.empty?

best_guess = sorted_releases.shift
display_release(best_guess.first, best_guess.last, :color => :green, :show_discography => true)

sorted_releases.each do |release, engineers|
  display_release(release, engineers)
end


