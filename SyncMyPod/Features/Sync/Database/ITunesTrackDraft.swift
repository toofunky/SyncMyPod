import Foundation

/// Everything needed to describe a new AAC track in the iTunesDB.
nonisolated struct ITunesTrackDraft: Equatable, Sendable {
    var title: String
    var artist = ""
    var album = ""
    var albumArtist = ""
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
    var artwork: ITunesTrackArtwork?

    var albumListArtist: String { albumArtist.isEmpty ? artist : albumArtist }
}
