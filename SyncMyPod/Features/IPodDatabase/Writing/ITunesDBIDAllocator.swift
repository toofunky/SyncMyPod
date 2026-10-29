import Foundation

/// Hands out record IDs above every ID already present, mirroring iTunes' single shared counter.
nonisolated struct ITunesDBIDAllocator {
    private static let idOffsets: [String: [Int]] = [
        "mhit": [0x10, 0x120], "mhip": [0x14], "mhia": [0x10], "mhii": [0x10]
    ]

    private var nextID: UInt32

    init(root: ITunesDBRecord) {
        nextID = Self.maximumID(in: root) + 1
    }

    mutating func allocate() -> UInt32 {
        defer { nextID += 1 }
        return nextID
    }

    private static func maximumID(in record: ITunesDBRecord) -> UInt32 {
        let own = (idOffsets[record.tag] ?? []).map { record.uint32(at: $0) }.max() ?? 0
        return record.children.map(maximumID(in:)).reduce(own, max)
    }
}
