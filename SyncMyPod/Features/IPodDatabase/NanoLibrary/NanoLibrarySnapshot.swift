import Foundation

/// Everything the nano's SQLite library is generated from, read from a finished (uncompressed) iTunesDB.
nonisolated struct NanoLibrarySnapshot: Sendable {
    private static let libraryPIDOffset = 0x48
    private static let versionOffset = 0x10

    let libraryPID: UInt64
    let databaseVersion: Int
    let items: [NanoLibraryItem]
    let playlists: [NanoLibraryPlaylist]
    let albums: [UInt32: NanoLibraryGroup]
    let artists: [UInt32: NanoLibraryGroup]

    init(database: Data) throws {
        let root = try ITunesDBRecordParser(data: database).parse()
        guard root.children.contains(where: { $0.isSection(.tracks) }) else { throw IPodSyncError.missingTrackList }
        let tracks = Self.list(.tracks, in: root)
        libraryPID = root.uint64(at: Self.libraryPIDOffset)
        databaseVersion = Int(root.uint32(at: Self.versionOffset))
        items = tracks.map(NanoLibraryItem.init(mhit:))
        let pidsByTrackID = Dictionary(tracks.map { ($0.uint32(at: 0x10), $0.uint64(at: 0x70)) },
                                       uniquingKeysWith: { first, _ in first })
        playlists = Self.playlistRecords(in: root)
            .map { NanoLibraryPlaylist(mhyp: $0, pidsByTrackID: pidsByTrackID) }
        albums = Self.groups(in: Self.list(.albums, in: root))
        artists = Self.groups(in: Self.list(.artists, in: root))
    }

    var masterPlaylist: NanoLibraryPlaylist? { playlists.first(where: \.isMaster) }

    private static func list(_ section: ITunesDBSectionType, in root: ITunesDBRecord) -> [ITunesDBRecord] {
        root.children.first { $0.isSection(section) }?.children.first?.children ?? []
    }

    /// iTunes writes nano databases with only the podcast-aware playlist section; the built-in media lists
    /// (Music, Movies, Audiobooks…) appear only in the smart playlist section.
    private static func playlistRecords(in root: ITunesDBRecord) -> [ITunesDBRecord] {
        let standard = list(.playlists, in: root)
        let playlists = standard.isEmpty ? list(.podcasts, in: root) : standard
        let known = Set(playlists.map { $0.uint64(at: 0x1C) })
        return playlists + list(.smartPlaylists, in: root).filter { !known.contains($0.uint64(at: 0x1C)) }
    }

    private static func groups(in records: [ITunesDBRecord]) -> [UInt32: NanoLibraryGroup] {
        Dictionary(records.map { (NanoLibraryGroup(record: $0).id, NanoLibraryGroup(record: $0)) },
                   uniquingKeysWith: { first, _ in first })
    }
}
