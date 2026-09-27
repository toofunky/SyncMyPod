import Foundation

/// Plain copies of a track's sortable fields; comparing these avoids thousands of SwiftData property reads.
nonisolated struct LibraryTrackSortKey: Sendable {
    let index: Int
    let title: String
    let artist: String
    let albumArtist: String
    let composer: String
    let album: String
    let genre: String
    let trackNumber: Int
    let discNumber: Int
    let duration: TimeInterval
    let bitrate: Int
    let codecName: String

    init(index: Int, track: LibraryTrack) {
        self.index = index
        title = track.title
        artist = track.artist
        albumArtist = track.albumArtist
        composer = track.composer
        album = track.album
        genre = track.genre
        trackNumber = track.trackNumber
        discNumber = track.discNumber
        duration = track.duration
        bitrate = track.bitrate
        codecName = track.codecName
    }
}
