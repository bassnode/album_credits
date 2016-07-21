module AlbumCredits

  class Finder
    include Display

    attr_reader :discogs

    def initialize(api_key="vTVvYBauSDUjTGNmVGdjqEavQHRWdkhtWerSqJul")
      @discogs = Discogs::Wrapper.new("album_credits", user_token: api_key)
    end

    def parse_discogs_id(search_result)
      search_result.uri.split('/').last
    end

    # @param [String] the main string to search for
    # @param [Hash,Optional] params
    # @option params [String] :format CD, HDCD, vinyl, etc.
    # @option params [String] :artist
    # @option params [Fixnum] :year
    def search(target, params={})
      sections = []
      params.each_pair do |key, val|
        sections << "#{key}:#{val}" if val
      end

      search_string = "#{target} AND " << sections.join(" AND ")
      debug "Searching for #{CGI.escape(search_string)}"

      begin
        discogs.search(CGI.escape(search_string), :type => 'releases')
      rescue  Discogs::UnknownResource => e
        debug "Nothing found for #{search_string} #{e}"
      end
    end

    def find_releases(artist, album)

      releases = []
      possibilities = discogs.search(album, type: 'release', artist: artist, format: 'album')

      if possibilities.pagination.items > 0
        possibilities.results.each do |found_album|
          begin
            release = discogs.get_release(found_album.id)
          rescue Exception => e
            debug "Failed to find release id #{found_album.id}: #{e}"
            next
          end
          # Make sure the album is actually in an Accepted state (as per Discogs).
          if release.status == 'Accepted'
            releases << release
          else
            debug "unacceptable: #{release.title} #{release.status}"
          end
        end
      else
        debug "no results for #{artist} #{album} #{year} #{format}"
      end

      raise AlbumCredits::NoReleasesFound.new(artist, album, year) if releases.empty?

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

    private
    def debug(txt)
      puts txt if debug?
    end

    def debug?
      ENV['DEBUG'].to_i == 1
    end
  end
end
