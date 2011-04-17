module AlbumCredits

  class NoReleasesFound < StandardError

    def initialize(artist, album, year=nil)
      msg = "No releases found for Artist: #{artist}  Album: #{album}" << " Year: #{year}" if year
      super(msg)
    end

  end
end
