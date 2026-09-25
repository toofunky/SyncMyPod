import Foundation

extension LibraryTrack {
    static let unknownArtist = "Unknown Artist"
    static let unknownAlbum = "Unknown Album"

    /// Album artist when tagged, so compilations stay together under one artist.
    var syncArtist: String {
        let name = albumArtist.isEmpty ? artist : albumArtist
        return name.isEmpty ? Self.unknownArtist : name
    }

    var syncAlbum: String { album.isEmpty ? Self.unknownAlbum : album }

    var syncAlbumKey: String { "\(syncArtist)\u{1F}\(syncAlbum)" }
}
