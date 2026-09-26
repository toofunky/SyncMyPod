import Foundation

/// Replaces user playlists in both playlist sections of an iTunesDB tree, leaving the master playlist alone.
nonisolated enum ITunesDBPlaylistWriter {
    private static let playlistIDOffset = 0x1C
    private static let databaseIDOffset = 0x70
    private static let settingsType: UInt32 = 100
    private static let sections: [ITunesDBSectionType] = [.playlists, .podcasts]

    /// Removes playlists whose ID is in `removing` or matches a draft's, then appends the drafts. Songs that
    /// aren't in the track list are left out.
    static func replace(_ drafts: [ITunesPlaylistDraft], removing ids: Set<UInt64>, in root: inout ITunesDBRecord,
                        allocator: inout ITunesDBIDAllocator) {
        let replaced = ids.union(drafts.map(\.id))
        let trackIDs = trackIDsByDatabaseID(in: root)
        let settings = masterSettings(in: root)
        let records = drafts.map { draft in
            PlaylistRecordBuilder.build(draft, items: items(for: draft, trackIDs: trackIDs, allocator: &allocator),
                                        settings: settings)
        }
        for index in root.children.indices where sections.contains(where: root.children[index].isSection) {
            guard !root.children[index].children.isEmpty else { continue }
            var list = root.children[index].children[0]
            list.children.removeAll { !$0.isMasterPlaylist && replaced.contains($0.uint64(at: playlistIDOffset)) }
            list.children += records
            root.children[index].children[0] = list
        }
    }

    private static func items(for draft: ITunesPlaylistDraft, trackIDs: [UInt64: UInt32],
                              allocator: inout ITunesDBIDAllocator) -> [ITunesDBRecord] {
        draft.databaseIDs.compactMap { databaseID in
            trackIDs[databaseID].map {
                PlaylistItemRecordBuilder.build(itemID: allocator.allocate(), trackID: $0, databaseID: databaseID,
                                                dateAdded: draft.createdAt)
            }
        }
    }

    private static func trackIDsByDatabaseID(in root: ITunesDBRecord) -> [UInt64: UInt32] {
        let tracks = root.children.first { $0.isSection(.tracks) }?.children.first?.children ?? []
        return Dictionary(tracks.map { ($0.uint64(at: databaseIDOffset), $0.uint32(at: 0x10)) },
                          uniquingKeysWith: { first, _ in first })
    }

    /// iTunes gives every playlist a type-100 display settings `mhod`; reuse the master playlist's.
    private static func masterSettings(in root: ITunesDBRecord) -> ITunesDBRecord? {
        let list = root.children.first { $0.isSection(.playlists) }?.children.first
        let master = list?.children.first(where: \.isMasterPlaylist)
        return master?.children.first { $0.tag == "mhod" && $0.recordType == settingsType }
    }
}
