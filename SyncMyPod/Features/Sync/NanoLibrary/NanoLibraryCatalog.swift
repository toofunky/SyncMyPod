import CryptoKit
import Foundation

/// The rankings and IDs derived from a snapshot that several tables share.
nonisolated struct NanoLibraryCatalog: Sendable {
    let snapshot: NanoLibrarySnapshot
    let titles: NanoSortRanking
    let artists: NanoSortRanking
    let albums: NanoSortRanking
    let composers: NanoSortRanking
    /// Composer IDs follow the names, so two composers sharing a sort key still get distinct IDs.
    let composerNames: NanoSortRanking
    let genres: NanoSortRanking
    let albumArtists: NanoSortRanking
    let playlists: NanoSortRanking
    /// Album-artist name → the persistent ID of its `artist` row.
    let artistPIDs: [String: UInt64]
    /// File kind ("MPEG audio file") → its `location_kind_map` ID, in order of first use.
    let kindIDs: [String: Int]

    init(snapshot: NanoLibrarySnapshot) {
        let items = snapshot.items
        self.snapshot = snapshot
        titles = NanoSortRanking(keys: items.map(\.sortTitle))
        artists = NanoSortRanking(keys: items.map(\.sortArtist))
        albums = NanoSortRanking(keys: items.map(\.sortAlbum))
        composers = NanoSortRanking(keys: items.map(\.sortComposer))
        composerNames = NanoSortRanking(keys: items.map { $0.string(.composer) })
        genres = NanoSortRanking(keys: items.map { $0.string(.genre) })
        albumArtists = NanoSortRanking(keys: items.map(\.albumArtistSortKey))
        playlists = NanoSortRanking(keys: snapshot.playlists.map(\.name))
        artistPIDs = Self.artistPIDs(for: snapshot)
        let kinds = items.compactMap { $0.string(.fileType) }.reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
        kindIDs = Dictionary(uniqueKeysWithValues: kinds.enumerated().map { ($1, $0 + 1) })
    }

    func artistPID(of item: NanoLibraryItem) -> UInt64? {
        item.albumArtistName.flatMap { artistPIDs[$0] }
    }

    /// The album's own artist when its `mhia` names one, so a compilation without an album artist is still filed
    /// under a single artist.
    func albumArtistPID(of item: NanoLibraryItem) -> UInt64? {
        snapshot.albums[item.albumID]?.artistName.flatMap { artistPIDs[$0] } ?? artistPID(of: item)
    }

    /// The `mhia` the track links to, or a stable ID derived from its album and album artist.
    func albumPID(of item: NanoLibraryItem) -> UInt64? {
        let album = item.string(.album)
        if let linked = snapshot.albums[item.albumID], linked.name == album { return linked.pid }
        guard let album else { return nil }
        return Self.stablePID("album", album, item.albumArtistName ?? "")
    }

    func composerPID(of item: NanoLibraryItem) -> Int {
        item.string(.composer) == nil ? 0 : composerNames.position(of: item.string(.composer))
    }

    func genreID(of item: NanoLibraryItem) -> Int {
        item.string(.genre) == nil ? 0 : genres.position(of: item.string(.genre))
    }

    /// Reuses `mhii` IDs by name so artist IDs stay stable; tracks SyncMyPod added get one derived from the name.
    private static func artistPIDs(for snapshot: NanoLibrarySnapshot) -> [String: UInt64] {
        var pids: [String: UInt64] = [:]
        for artist in snapshot.artists.values {
            if let name = artist.name, pids[name] == nil { pids[name] = artist.pid }
        }
        for name in snapshot.items.compactMap(\.albumArtistName) where pids[name] == nil {
            pids[name] = stablePID("artist", name)
        }
        return pids
    }

    private static func stablePID(_ parts: String...) -> UInt64 {
        let digest = SHA256.hash(data: Data(parts.joined(separator: "\u{0}").utf8))
        return digest.prefix(8).reduce(0) { $0 << 8 | UInt64($1) }
    }
}
