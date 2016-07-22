module AlbumCredits

  module Display

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


    def default_color
      :white
    end

    def engineer_discog_max
      100
    end

    # Prints the text in color
    #
    # @param [String] the text to print
    # @param [Hash] opts
    # @options opts [Boolean] :bold
    # @options opts [Symbol] :color (default is .default_color)
    def cp(text, opts={})
      embolden = opts[:bold] ? COLORS[:bold] : ''
      color = opts[:color] || default_color
      puts "#{embolden}#{COLORS[color]}#{text}#{COLORS[:clear]}"
    end

    def image_uri_for_release(release)
      return if release.images.nil?
      img = release.images.detect{|i| i.type == 'primary'}
      img = release.images.detect{|i| i.type == 'secondary'} if img.nil?
      img.uri if img
    end

    def display_release(release, engineers, opts={})
      cp "="*40
      cp release.title
      cp "#{release.tracklist.size} songs, released: #{release.released}"
      cp release.uri
      cp release.notes
      cp ""
      display_engineer_data(engineers, opts)
    end

    def get_artist_discog(artist)
      begin
        discogs.get_artists_releases(artist.id, per_page: engineer_discog_max, page: 1)
      rescue Exception => e
        puts e
      end
    end

    # IDEA: show a cross-section of their work.
    # maybe start with around the year that current album was released if there are many.
    # ALSO: could filter their discog. output by x-ref w/ the role they
    # played on this album. e.g. only show Bob Ludwig's mastering work, not mixing.
    def display_engineer_data(engineers, opts={})
      show_discography = opts[:show_discography] == true
      displayed = []

      cp "Engineers:", :color => :yellow
      engineers.each do |engineer|
        next if displayed.include? engineer.name
        cp "#{engineer.name}: #{engineer.role}", :bold => true, :color => :red

        engineer_details = discogs.get_artist(engineer.id)
        if (!engineer_details.nil?)
          aka = engineer_details.namevariations || []
          aka << engineer_details.aliases.map(&:name) unless engineer_details.aliases.nil?
          if !(aliases = aka.flatten.uniq.sort).empty?
            cp "AKA: #{aliases.first(10).join(', ')}"
          end
        end

        # Print the engineer's discography
        engineer_discog = get_artist_discog(engineer_details)

        if show_discography && !engineer_discog.nil? && engineer.role.match(/assisted|assistant|additional/i).nil?
          discog_cnt = engineer_discog.releases.size == engineer_discog_max ? "#{engineer_discog_max}+" : engineer_discog.releases.size
          cp "#{discog_cnt} releases in discography", :color => :yellow

          cp engineer_details.uri

          engineer_discog.releases.group_by{ |disk| disk.year }.sort_by{ |year, _| year || 0 }.reverse.each do |year, albums|
            cp year, :bold => true, :color => :blue
            albums.each do |a|
              cp "  * #{a.artist} - \"#{a.title}\", [#{a.role}]"
            end
          end

          displayed << engineer_details.name
        end
        puts
      end
    end
  end
end
