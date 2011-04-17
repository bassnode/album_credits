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
        debug "Nothing found for #{search_string}"
      end
    end

    def find_releases(artist, album, year=nil)

      releases = []

      [nil, 'CD', 'HDCD', 'vinyl'].each do |format|

        possibilities = search(album, :artist => artist, :year => year, :format => format)

        if possibilities && possibilities.searchresults.size > 0
          possibilities.searchresults.each do |found_album|
            release = discogs.get_release(parse_discogs_id(found_album))
            # Make sure the album is actually what we think it is and that it
            # is in an Accepted state (as per Discogs).
            if release.title =~ /#{album}/i && release.status == 'Accepted'
              releases << release
            else
              debug "unacceptable: #{release.title} #{release.status}"
            end
          end
        else
          debug "no results for #{artist} #{album} #{year} #{format}"
        end


        raise AlbumCredits::NoReleasesFound.new(artist, album, year) if releases.empty?
      end

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
