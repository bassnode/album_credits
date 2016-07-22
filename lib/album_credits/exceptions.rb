module AlbumCredits

  class NoReleasesFound < StandardError

    def initialize(artist, album)
      msg = "No releases found for Artist: #{artist}  Album: #{album}"
      super(msg)
    end

  end
end
