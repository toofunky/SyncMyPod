import Foundation

/// Plain copies of a track's sortable fields; comparing these avoids thousands of SwiftData property reads.
nonisolated struct LibraryTrackSortKey: Sendable {
    let index: Int
    let title: String
    let artist: String
    let albumArtist: String
    let composer: String
    let album: String
    let sortTitle: String
    let sortArtist: String
    let sortAlbumArtist: String
    let sortComposer: String
    let sortAlbum: String
    let sortGenre: String
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
        sortTitle = title.sortName(tagged: track.sortTitleTag)
        sortArtist = artist.sortName(tagged: track.sortArtistTag)
        sortAlbumArtist = albumArtist.sortName(tagged: track.sortAlbumArtistTag)
        sortComposer = composer.sortName(tagged: track.sortComposerTag)
        sortAlbum = album.sortName(tagged: track.sortAlbumTag)
        sortGenre = track.genre.sortName
        trackNumber = track.trackNumber
        discNumber = track.discNumber
        duration = track.duration
        bitrate = track.bitrate
        codecName = track.codecName
    }
}
