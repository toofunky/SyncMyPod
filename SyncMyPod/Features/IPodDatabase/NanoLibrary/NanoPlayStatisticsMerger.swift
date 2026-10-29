import Foundation

/// Copies the nano's running totals into the matching `mhit`s. The nano also writes a Play Counts file with the same
/// plays as deltas, so that file must not be merged as well.
nonisolated enum NanoPlayStatisticsMerger {
    private static let maximumRating: UInt32 = 100

    /// Returns whether any track changed.
    static func merge(_ statistics: [UInt64: NanoPlayStatistics], into root: inout ITunesDBRecord) -> Bool {
        guard !statistics.isEmpty,
              let section = root.children.firstIndex(where: { $0.isSection(.tracks) }),
              !root.children[section].children.isEmpty else { return false }
        var changed = false
        for index in root.children[section].children[0].children.indices {
            var mhit = root.children[section].children[0].children[index]
            guard let entry = statistics[mhit.uint64(at: 0x70)] else { continue }
            let original = mhit
            apply(entry, to: &mhit)
            if mhit != original {
                root.children[section].children[0].children[index] = mhit
                changed = true
            }
        }
        return changed
    }

    /// Offsets match what iTunes writes for the nano: skips at 0x98 and the last skip at 0xA0.
    private static func apply(_ entry: NanoPlayStatistics, to mhit: inout ITunesDBRecord) {
        mhit.set(entry.playCount, at: 0x50)
        mhit.set(entry.skipCount, at: 0x98)
        let lastPlayed = NanoTimestamp.localMacSeconds(from: entry.lastPlayed)
        if lastPlayed > mhit.uint32(at: 0x58) { mhit.set(lastPlayed, at: 0x58) }
        let lastSkipped = NanoTimestamp.localMacSeconds(from: entry.lastSkipped)
        if lastSkipped > mhit.uint32(at: 0xA0) { mhit.set(lastSkipped, at: 0xA0) }
        if entry.rating <= maximumRating { mhit.set(UInt8(entry.rating), at: 0x1F) }
        mhit.set(entry.bookmarkMilliseconds, at: 0x6C)
    }
}
