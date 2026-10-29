import Foundation

/// Everything needed to describe a new track in the iTunesDB.
nonisolated struct ITunesTrackDraft: Equatable, Sendable {
    var title: String
    var artist = ""
    var album = ""
    var albumArtist = ""
    var composer = ""
    var genre = ""
    var location = ""
    var fileSize = 0
    var duration: TimeInterval = 0
    var trackNumber = 0
    var trackCount = 0
    var discNumber = 0
    var discCount = 0
    var year = 0
    var bitrate = 0
    var sampleRate = 0
    var dateAdded = Date.now
    var lastModified = Date.now
    var codec = AudioCodec.aac
    var artwork: ITunesTrackArtwork?
    var sortTitle = ""
    var sortArtist = ""
    var sortAlbumArtist = ""
    var sortAlbum = ""
    var sortComposer = ""
    /// Whether the file holds lyrics. The iPod only reads them when the track says so.
    var hasLyrics = false
    /// Podcast episodes and audiobooks are listed in the iPod's Podcasts and Audiobooks menus instead of with the
    /// music, resume where they were left and aren't shuffled.
    var mediaKind = SyncMediaKind.music
    var releaseDate: Date?

    var albumListArtist: String { albumArtist.isEmpty ? artist : albumArtist }
}
