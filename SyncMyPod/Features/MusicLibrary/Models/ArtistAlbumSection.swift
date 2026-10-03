import Foundation

/// One album in the Artists view, with its songs in play order.
struct ArtistAlbumSection: Identifiable {
    let album: LibraryAlbum
    let tracks: [LibraryTrack]

    var id: LibraryAlbum.ID { album.id }
    var duration: TimeInterval { tracks.reduce(0) { $0 + $1.duration } }
    var hasSeveralDiscs: Bool { Set(tracks.map(\.discNumber)).count > 1 }

    /// The orders the Artists view offers; sorting by year puts undated albums last either way.
    static let sortOrders: [AlbumSortOrder] = [.year, .yearDescending, .album]

    static func sections(from tracks: [LibraryTrack], sortedBy order: AlbumSortOrder = .year) -> [ArtistAlbumSection] {
        let tracksByAlbum = Dictionary(grouping: tracks, by: \.syncAlbumKey)
        return order.sorted(LibraryAlbum.albums(from: tracks)).map { album in
            ArtistAlbumSection(album: album, tracks: LibraryTrack.albumOrdered(tracksByAlbum[album.id] ?? []))
        }
    }
}
