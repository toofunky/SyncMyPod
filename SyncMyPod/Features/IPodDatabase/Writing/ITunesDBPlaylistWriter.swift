import Foundation

/// Replaces user playlists in both playlist sections of an iTunesDB tree, leaving the master playlist alone.
/// The Podcasts list is flat in the playlist section and grouped by show in the podcast section, as libgpod
/// writes it, and replaces any Podcasts list already there.
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
        let replacesPodcasts = drafts.contains(where: \.isPodcasts)
        let assembler = PlaylistRecordAssembler(trackIDs: trackIDsByDatabaseID(in: root), settings: masterSettings(in: root))
        let shared = drafts.filter { !$0.isPodcasts }
            .map { assembler.record(for: $0, grouped: false, allocator: &allocator) }
        for index in root.children.indices where sections.contains(where: root.children[index].isSection) {
            guard !root.children[index].children.isEmpty else { continue }
            let grouped = root.children[index].isSection(.podcasts)
            let podcasts = drafts.filter(\.isPodcasts)
                .map { assembler.record(for: $0, grouped: grouped, allocator: &allocator) }
            var list = root.children[index].children[0]
            list.children.removeAll { playlist in
                !playlist.isMasterPlaylist && (replaced.contains(playlist.uint64(at: playlistIDOffset))
                                               || (replacesPodcasts && isPodcastList(playlist)))
            }
            list.children += shared + podcasts
            root.children[index].children[0] = list
        }
    }

    static func isPodcastList(_ playlist: ITunesDBRecord) -> Bool {
        playlist.tag == "mhyp" && playlist.header.count >= PlaylistRecordBuilder.podcastFlagOffset + 2
            && playlist.header.read(UInt16.self, at: PlaylistRecordBuilder.podcastFlagOffset) == 1
    }

    private static func trackIDsByDatabaseID(in root: ITunesDBRecord) -> [UInt64: UInt32] {
        let tracks = root.children.first { $0.isSection(.tracks) }?.children.first?.children ?? []
        return Dictionary(tracks.map { ($0.uint64(at: databaseIDOffset), $0.uint32(at: 0x10)) },
                          uniquingKeysWith: { first, _ in first })
    }

    /// iTunes gives every playlist a type-100 display settings `mhod`; reuse the master playlist's.
    private static func masterSettings(in root: ITunesDBRecord) -> ITunesDBRecord? {
        let lists = sections.compactMap { section in root.children.first { $0.isSection(section) }?.children.first }
        let master = lists.lazy.compactMap { $0.children.first(where: \.isMasterPlaylist) }.first
        return master?.children.first { $0.tag == "mhod" && $0.recordType == settingsType }
    }
}
