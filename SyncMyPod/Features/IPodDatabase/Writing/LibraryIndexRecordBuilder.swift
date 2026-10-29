import Foundation

/// Regenerates the master playlist's sorted index (type 52) and jump table (type 53) `mhod`s.
nonisolated struct LibraryIndexRecordBuilder {
    static let indexType: UInt32 = 52
    static let jumpTableType: UInt32 = 53
    private static let digitLetter = UInt16(UInt8(ascii: "0"))
    private static let comparison: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

    /// Tracks in master playlist order; index entries are positions in this array.
    let tracks: [ITunesTrack]

    func records() -> [ITunesDBRecord] {
        LibraryIndexSortType.allCases.flatMap { sortType in
            let keys = tracks.map(sortType.sortKey(for:))
            let order = sortedPositions(keys)
            return [indexRecord(sortType, order: order), jumpTableRecord(sortType, order: order, keys: keys)]
        }
    }

    func sortedPositions(_ keys: [[String]]) -> [Int] {
        keys.indices.sorted { lhs, rhs in
            for (left, right) in zip(keys[lhs], keys[rhs]) {
                let result = left.compare(right, options: Self.comparison, locale: .current)
                if result != .orderedSame { return result == .orderedAscending }
            }
            return lhs < rhs
        }
    }

    private func indexRecord(_ sortType: LibraryIndexSortType, order: [Int]) -> ITunesDBRecord {
        var payload = Data(count: 0x30)
        payload.write(sortType.rawValue, at: 0x00)
        payload.write(UInt32(order.count), at: 0x04)
        for position in order { payload.append(contentsOf: Self.bytes(UInt32(position))) }
        return ITunesDBRecordFactory.mhod(type: Self.indexType, payload: payload)
    }

    private func jumpTableRecord(_ sortType: LibraryIndexSortType, order: [Int],
                                 keys: [[String]]) -> ITunesDBRecord {
        let groups = letterGroups(order.map { Self.jumpLetter(for: keys[$0].first ?? "") })
        var payload = Data(count: 0x10)
        payload.write(sortType.rawValue, at: 0x00)
        payload.write(UInt32(groups.count), at: 0x04)
        for group in groups {
            payload.append(contentsOf: Self.bytes(UInt32(group.letter)))
            payload.append(contentsOf: Self.bytes(UInt32(group.start)))
            payload.append(contentsOf: Self.bytes(UInt32(group.count)))
        }
        return ITunesDBRecordFactory.mhod(type: Self.jumpTableType, payload: payload)
    }

    private func letterGroups(_ letters: [UInt16]) -> [(letter: UInt16, start: Int, count: Int)] {
        var groups: [(letter: UInt16, start: Int, count: Int)] = []
        for (position, letter) in letters.enumerated() {
            if groups.last?.letter == letter {
                groups[groups.count - 1].count += 1
            } else {
                groups.append((letter, position, 1))
            }
        }
        return groups
    }

    static func jumpLetter(for key: String) -> UInt16 {
        guard let first = key.first else { return 0 }
        guard first.isLetter else { return digitLetter }
        let folded = String(first).folding(options: comparison, locale: .current).uppercased()
        return folded.utf16.first ?? digitLetter
    }

    private static func bytes(_ value: UInt32) -> Data {
        withUnsafeBytes(of: value.littleEndian) { Data($0) }
    }
}
