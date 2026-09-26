import Foundation

/// Builds an `mhip` playlist entry with its type-100 position `mhod`.
nonisolated enum PlaylistItemRecordBuilder {
    private static let headerLength = 0x4C
    private static let positionType: UInt32 = 100

    static func build(itemID: UInt32, trackID: UInt32, databaseID: UInt64, dateAdded: Date) -> ITunesDBRecord {
        var position = Data(count: 0x14)
        position.write(itemID, at: 0x00)
        let mhod = ITunesDBRecordFactory.mhod(type: positionType, payload: position)
        var mhip = ITunesDBRecordFactory.record("mhip", headerLength: headerLength,
                                                body: .container([mhod], trailer: Data()))
        mhip.set(UInt32(1), at: 0x0C)
        mhip.set(itemID, at: 0x14)
        mhip.set(trackID, at: 0x18)
        mhip.set(ITunesTimestamp.seconds(from: dateAdded), at: 0x1C)
        mhip.set(databaseID, at: 0x2C)
        return mhip
    }
}
