import Foundation

/// Builds an `mhip` playlist entry with its type-100 position `mhod`, and the Podcasts list's show headers.
nonisolated enum PlaylistItemRecordBuilder {
    static let podcastGroupFlagOffset = 0x10
    static let podcastGroupFlag: UInt32 = 0x100
    private static let headerLength = 0x4C
    private static let positionType: UInt32 = 100
    private static let podcastGroupRefOffset = 0x20

    /// `podcastGroup` is the item ID of the show header an episode in the Podcasts list sits under.
    static func build(itemID: UInt32, trackID: UInt32, databaseID: UInt64, dateAdded: Date,
                      podcastGroup: UInt32 = 0) -> ITunesDBRecord {
        var position = Data(count: 0x14)
        position.write(itemID, at: 0x00)
        let mhod = ITunesDBRecordFactory.mhod(type: positionType, payload: position)
        var mhip = ITunesDBRecordFactory.record("mhip", headerLength: headerLength,
                                                body: .container([mhod], trailer: Data()))
        mhip.set(UInt32(1), at: 0x0C)
        mhip.set(itemID, at: 0x14)
        mhip.set(trackID, at: 0x18)
        mhip.set(ITunesTimestamp.seconds(from: dateAdded), at: 0x1C)
        mhip.set(podcastGroup, at: podcastGroupRefOffset)
        mhip.set(databaseID, at: 0x2C)
        return mhip
    }

    /// A show's header in the Podcasts list: no track, just the show's name, as libgpod writes it.
    static func podcastGroup(itemID: UInt32, show: String) -> ITunesDBRecord {
        let title = ITunesDBRecordFactory.string(type: ITunesStringField.title.rawValue, value: show)
        var mhip = ITunesDBRecordFactory.record("mhip", headerLength: headerLength,
                                                body: .container([title], trailer: Data()))
        mhip.set(UInt32(1), at: 0x0C)
        mhip.set(podcastGroupFlag, at: podcastGroupFlagOffset)
        mhip.set(itemID, at: 0x14)
        return mhip
    }
}
