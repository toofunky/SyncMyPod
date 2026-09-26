import Foundation

/// Parses `iPod_Control/iTunes/Play Counts`: an `mhdp` header followed by one entry per `mhit`, in track-list order.
nonisolated enum PlayCountsFile {
    private static let minimumEntryLength = 0x0C
    private static let ratingEntryLength = 0x10
    private static let skipEntryLength = 0x1C

    static func parse(_ data: Data) -> [PlayCountEntry]? {
        guard data.count >= 0x10, data.prefix(4) == Data("mhdp".utf8) else { return nil }
        let headerLength = Int(data.read(UInt32.self, at: 0x04))
        let entryLength = Int(data.read(UInt32.self, at: 0x08))
        let count = Int(data.read(UInt32.self, at: 0x0C))
        guard entryLength >= minimumEntryLength, headerLength + entryLength * count <= data.count else { return nil }
        return (0..<count).map { entry(in: data, at: headerLength + $0 * entryLength, length: entryLength) }
    }

    private static func entry(in data: Data, at offset: Int, length: Int) -> PlayCountEntry {
        var entry = PlayCountEntry(playCount: data.read(UInt32.self, at: offset),
                                   lastPlayed: data.read(UInt32.self, at: offset + 0x04),
                                   bookmark: data.read(UInt32.self, at: offset + 0x08))
        if length >= ratingEntryLength { entry.rating = data.read(UInt32.self, at: offset + 0x0C) }
        if length >= skipEntryLength {
            entry.skipCount = data.read(UInt32.self, at: offset + 0x14)
            entry.lastSkipped = data.read(UInt32.self, at: offset + 0x18)
        }
        return entry
    }
}
