import Foundation

/// Builds a user `mhyp` playlist with its title `mhod`, an optional settings `mhod` and its `mhip` entries.
nonisolated enum PlaylistRecordBuilder {
    private static let headerLength = 0x6C
    private static let manualSortOrder: UInt32 = 1

    static func build(_ draft: ITunesPlaylistDraft, items: [ITunesDBRecord], settings: ITunesDBRecord?) -> ITunesDBRecord {
        let title = ITunesDBRecordFactory.string(type: ITunesStringField.title.rawValue, value: draft.name)
        let mhods = [title] + (settings.map { [$0] } ?? [])
        var mhyp = ITunesDBRecordFactory.record("mhyp", headerLength: headerLength,
                                                body: .container(mhods + items, trailer: Data()))
        mhyp.set(UInt32(mhods.count), at: 0x0C)
        mhyp.set(UInt32(items.count), at: 0x10)
        mhyp.set(ITunesTimestamp.seconds(from: draft.createdAt), at: 0x18)
        mhyp.set(draft.id, at: 0x1C)
        mhyp.set(UInt16(1), at: 0x28)
        mhyp.set(manualSortOrder, at: 0x2C)
        return mhyp
    }
}
