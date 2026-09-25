import Foundation

/// Folds the iPod's Play Counts entries into the matching `mhit`s, as iTunes and libgpod do before rewriting.
nonisolated enum PlayCountsMerger {
    private static let maximumRating: UInt32 = 100

    /// Returns `false` without changing anything if the entries don't line up with the track list.
    static func merge(_ entries: [PlayCountEntry], into root: inout ITunesDBRecord) -> Bool {
        guard let section = root.children.firstIndex(where: { $0.isSection(.tracks) }),
              !root.children[section].children.isEmpty,
              root.children[section].children[0].children.count == entries.count else { return false }
        for (index, entry) in entries.enumerated() {
            apply(entry, to: &root.children[section].children[0].children[index])
        }
        return true
    }

    private static func apply(_ entry: PlayCountEntry, to mhit: inout ITunesDBRecord) {
        if entry.playCount > 0 {
            mhit.set(mhit.uint32(at: 0x50) &+ entry.playCount, at: 0x50)
            mhit.set(entry.playCount, at: 0x54)
        }
        if entry.lastPlayed > mhit.uint32(at: 0x58) { mhit.set(entry.lastPlayed, at: 0x58) }
        if entry.bookmark > 0 { mhit.set(entry.bookmark, at: 0x6C) }
        if let rating = entry.rating, rating <= maximumRating { mhit.set(UInt8(rating), at: 0x1F) }
        if entry.skipCount > 0 { mhit.set(mhit.uint32(at: 0x9C) &+ entry.skipCount, at: 0x9C) }
        if entry.lastSkipped > mhit.uint32(at: 0xA0) { mhit.set(entry.lastSkipped, at: 0xA0) }
    }
}
