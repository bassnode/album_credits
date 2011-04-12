module AlbumCredits

  class Finder
    include Display

    attr_reader :discogs

    def initialize(api_key="bff9085fc7")
      @discogs = Discogs::Wrapper.new(api_key)
    end

    def parse_discogs_id(search_result)
      search_result.uri.split('/').last
    end

    def find_releases(artist, album, year=nil)
      releases = []
      [nil, 'CD', 'HDCD', 'vinyl'].each do |format|
        format = " AND format:#{format}" if format
        query = CGI.escape("#{album} AND artist:#{artist}#{format}")
        begin
          possibilities = discogs.search(query, :type => 'releases')
        rescue  Discogs::UnknownResource => e
          puts "Not found: #{e}"
          next
        end
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

      # Sometimes Discogs returns duplicate releases so
      # filter out any duplicates based on id.
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
      discogs.get_artist(CGI.escape(artist)) rescue []
    end

  end
end
