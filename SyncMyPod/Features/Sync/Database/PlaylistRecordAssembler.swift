import Foundation

/// Builds playlist records from drafts, pointing their entries at the database's tracks.
nonisolated struct PlaylistRecordAssembler {
    /// Track IDs, which playlist entries use, keyed by database ID.
    let trackIDs: [UInt64: UInt32]
    /// The display settings `mhod` every playlist gets.
    let settings: ITunesDBRecord?

    /// `grouped` lists the Podcasts list's episodes under a header for each show, for the podcast section.
    func record(for draft: ITunesPlaylistDraft, grouped: Bool, allocator: inout ITunesDBIDAllocator) -> ITunesDBRecord {
        let items = grouped && draft.isPodcasts
            ? groupedItems(for: draft, allocator: &allocator)
            : items(for: draft.databaseIDs, of: draft, group: 0, allocator: &allocator)
        return PlaylistRecordBuilder.build(draft, items: items, settings: settings)
    }

    /// Each show's header, then its episodes, with shows in the order they first appear.
    private func groupedItems(for draft: ITunesPlaylistDraft, allocator: inout ITunesDBIDAllocator) -> [ITunesDBRecord] {
        let shows = draft.podcastShows ?? []
        var seen = Set<String>()
        var records: [ITunesDBRecord] = []
        for show in shows where seen.insert(show).inserted {
            let group = allocator.allocate()
            let episodes = zip(draft.databaseIDs, shows).filter { $0.1 == show }.map(\.0)
            records.append(PlaylistItemRecordBuilder.podcastGroup(itemID: group, show: show))
            records += items(for: episodes, of: draft, group: group, allocator: &allocator)
        }
        return records
    }

    private func items(for databaseIDs: [UInt64], of draft: ITunesPlaylistDraft, group: UInt32,
                       allocator: inout ITunesDBIDAllocator) -> [ITunesDBRecord] {
        databaseIDs.compactMap { databaseID in
            trackIDs[databaseID].map {
                PlaylistItemRecordBuilder.build(itemID: allocator.allocate(), trackID: $0, databaseID: databaseID,
                                                dateAdded: draft.createdAt, podcastGroup: group)
            }
        }
    }
}
