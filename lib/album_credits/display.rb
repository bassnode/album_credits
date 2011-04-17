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

    @default_color = :white
    attr_accessor :default_color

    # Prints the text in color
    #
    # @param [String] the text to print
    # @param [Hash] opts
    # @options opts [Boolean] :bold
    # @options opts [Symbol] :color (default is .default_color)
    def cp(text, opts={})
      embolden = opts[:bold] ? COLORS[:bold] : ''
      color = opts[:color] || @default_color
      puts "#{embolden}#{COLORS[color]}#{text}#{COLORS[:clear]}"
    end

    def image_uri_for_release(release)
      return if release.images.nil?
      img = release.images.detect{|i| i.type == 'primary'}
      img = release.images.detect{|i| i.type == 'secondary'} if img.nil?
      img.uri if img
    end

    def display_release(release, engineers, opts={})
      @default_color = opts.delete(:color) || :white

      cp "="*40
      cp "#{release.title} #{release.released} ID: #{release.id}"
      cp "#{release.tracklist.size} songs"
      cp image_uri_for_release(release)
      cp release.notes

      display_engineer_data(engineers, opts)
    end

    # TODO: Put logical engineer sorting
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
        cp "#{engineer.role} #{engineer.name}", :bold => true, :color => :red

        # Print the engineer's discography
        if show_discography && !(artist = discogs.get_artist(CGI.escape(engineer.name))).nil?
          aka = artist.aliases || []
          aka << artist.namevariations || []

          cp "AKA: #{aka.flatten.uniq.sort.join(', ')}"
          cp "#{artist.releases.size} releases in discography", :color => :yellow

          # Don't show discog for assistants
          unless engineer.role =~ /assisted|assistant|additional/i
            artist.releases.group_by{ |disk| disk.artist }.sort_by{ |artist, albums| artist }.each do |artist, albums|
              cp artist.to_s + " (#{albums.size} total)", :bold => true, :color => :blue
              # Print the oldest version of this album
              albums.group_by{ |a| a.title }.each do |title, albums|
                artist_release = albums.sort_by{ |album| album.year.to_i }.first
                cp "\t* #{artist_release.title} [#{artist_release.year} #{artist_release.label}]"
              end
            end
          end

          displayed << engineer.name
          puts
        end
      end
    end
  end
end
