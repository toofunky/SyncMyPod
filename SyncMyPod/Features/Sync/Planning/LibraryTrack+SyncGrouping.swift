import Foundation

extension LibraryTrack {
    static let unknownArtist = "Unknown Artist"
    static let unknownAlbum = "Unknown Album"
    static let unknownGenre = "Unknown Genre"

    /// Album artist when tagged, so compilations stay together under one artist.
    var syncArtist: String {
        let name = albumArtist.isEmpty ? artist : albumArtist
        return name.isEmpty ? Self.unknownArtist : name
    }

    var syncArtistSortName: String {
        albumArtist.isEmpty ? syncArtist.sortName(tagged: sortArtistTag)
            : syncArtist.sortName(tagged: sortAlbumArtistTag)
    }

    var syncAlbum: String { album.isEmpty ? Self.unknownAlbum : album }

    var syncAlbumKey: String { "\(syncArtist)\u{1F}\(syncAlbum)" }

    var syncGenre: String {
        let name = genre.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? Self.unknownGenre : name
    }

    func syncSnapshot(preservingAlbumArtist: Bool) -> SyncTrackSnapshot {
        SyncTrackSnapshot(filePath: filePath, artist: syncArtist, artistSortName: syncArtistSortName,
                          album: syncAlbum, albumSortName: syncAlbum.sortName(tagged: sortAlbumTag), albumKey: syncAlbumKey,
                          genre: syncGenre, request: syncRequest(preservingAlbumArtist: preservingAlbumArtist))
    }
}
