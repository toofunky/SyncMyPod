import Foundation

/// Groups tracks by album on both sides of a sync, using the album artist when there is one.
nonisolated struct IPodAlbumKey: Hashable, Sendable {
    let artist: String
    let album: String

    init(artist: String, albumArtist: String, album: String) {
        self.artist = (albumArtist.isEmpty ? artist : albumArtist).lowercased()
        self.album = album.lowercased()
    }

    init(_ tags: TrackTags) {
        self.init(artist: tags.artist, albumArtist: tags.albumArtist, album: tags.album)
    }

    init(_ track: ITunesTrack) {
        self.init(artist: track.artist, albumArtist: track.strings[.albumArtist] ?? "", album: track.album)
    }
}
