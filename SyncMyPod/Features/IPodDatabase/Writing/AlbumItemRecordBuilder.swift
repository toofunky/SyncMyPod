import Foundation

/// Builds an `mhia` album-list entry (type-4 section) with album and artist `mhod`s.
nonisolated enum AlbumItemRecordBuilder {
    static let albumType: UInt32 = 200
    static let artistType: UInt32 = 201
    private static let headerLength = 0x58
    private static let unknownConstant: UInt32 = 2

    static func build(albumID: UInt32, album: String, artist: String) -> ITunesDBRecord {
        let strings = [
            ITunesDBRecordFactory.string(type: albumType, value: album),
            ITunesDBRecordFactory.string(type: artistType, value: artist)
        ]
        var mhia = ITunesDBRecordFactory.record("mhia", headerLength: headerLength,
                                                body: .container(strings, trailer: Data()))
        mhia.set(UInt32(strings.count), at: 0x0C)
        mhia.set(albumID, at: 0x10)
        mhia.set(UInt64.random(in: 1...UInt64.max), at: 0x14)
        mhia.set(unknownConstant, at: 0x1C)
        return mhia
    }
}
