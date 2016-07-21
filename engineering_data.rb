require 'rubygems'
require 'discogs'
require 'awesome_print'

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

def color_puts(text, color=:white, bold=false)
  embolden = bold ? COLORS[:bold] : ''
  puts "#{embolden}#{COLORS[color]}#{text}#{COLORS[:clear]}"
end

def discogs
  return @discogs if @discogs
  @discogs = Discogs::Wrapper.new("album_credits", user_token: "vTVvYBauSDUjTGNmVGdjqEavQHRWdkhtWerSqJul")
end

def find_releases(artist, album)
  releases = []
  possibilities = discogs.search(album, type: 'release', artist: artist)
  if possibilities.pagination.items > 0
    puts "Found #{possibilities.pagination.items} to look through"
    possibilities.results.each do |found_album|
      begin
        release = discogs.get_release(found_album.id)
      rescue Exception => e
        puts "Failed to find release id #{found_album.id}: #{e}"
        next
      end
      # Make sure the album is actually is in an Accepted state (as per Discogs).
      if release.status == 'Accepted'
        releases << release
      else
        puts "#{release.artists.first.name} - #{release.title} Status: #{release.status}"
      end
    end
  else
    puts "no results for #{artist} #{album}"
  end

  # Only return unique releases
  seen = {}
  uniq_releases = releases.inject([]) do |uniq, rel|
    unless seen.has_key?(rel.id)
      seen[rel.id] = 1
      uniq << rel
    end
    uniq
  end

  uniq_releases
end

def engineers_for_release(release)
  if release.extraartists && !(engineers = release.extraartists.select{|a| a.role =~ /mix|master|engineer/i}).empty?
    return engineers
  end
end

def get_artist_discog(artist)
  begin
    discogs.get_artists_releases(artist.id, per_page: 25, page: 1)
  rescue Exception => e
    puts e
  end
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
  label = release.labels.empty? ? "" : "[#{release.labels.first.name}]"
  color_puts "="*40, color
  color_puts "#{release.artists.first.name} - #{release.title} #{release.released} #{label}", color
  color_puts release.uri, color
  color_puts "#{release.tracklist.size} songs", color
  color_puts image_uri_for_release(release), color
  color_puts release.notes, color
  color_puts "Engineers:", color
  engineers.each do |engineer|
    color_puts "#{engineer.role} #{engineer.name}", color, true
    # Print the first 100 releases in the engineer's discography
    releases = get_artist_discog(engineer)
    if show_discography && !releases.nil?
      sorted_releases = releases.releases.sort_by {|rel| rel.year.nil? ? 0 : rel.year }.reverse
      color_puts "Recent releases in discography", color
      sorted_releases.each do |disk|
        color_puts "\t* #{disk.year} #{disk.artist} - #{disk.title} [#{disk.role}]", color
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
releases = find_releases(artist, album)
raise "No releases" if releases.empty?
puts "Found #{releases.size} releases"

sorted_releases = releases.inject([]) do |rel_array, release|
  unless (engineers = engineers_for_release(release)).nil?
    rel_array << [release, engineers]
  end
  rel_array
end.sort_by{|arr| arr.last.size}.reverse

raise "No engineering data :/" if sorted_releases.empty?

best_guess = sorted_releases.shift
display_release(best_guess.first, best_guess.last, color: :green, show_discography: true)
#ap best_guess.first
#sorted_releases.each do |release, engineers|
 # ap release
 # display_release(release, engineers)
#end

