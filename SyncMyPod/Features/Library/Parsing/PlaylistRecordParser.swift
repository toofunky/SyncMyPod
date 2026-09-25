import Foundation

nonisolated struct PlaylistRecordParser {
    let reader: BinaryReader

    func parse(at offset: Int) throws -> ITunesPlaylist {
        try reader.expectTag("mhyp", at: offset)
        let headerLength = try reader.int(at: offset + 0x04)
        let stringCount = try reader.int(at: offset + 0x0C)
        let itemCount = try reader.int(at: offset + 0x10)
        let strings = try StringRecordParser(reader: reader)
            .parseAll(startingAt: offset + headerLength, count: stringCount)
        return try ITunesPlaylist(
            id: reader.uint64(at: offset + 0x1C),
            name: strings.values[.title] ?? "",
            isMaster: reader.uint8(at: offset + 0x14) == 1,
            createdAt: reader.macDate(at: offset + 0x18),
            trackIDs: parseTrackIDs(startingAt: strings.end, count: itemCount)
        )
    }

    private func parseTrackIDs(startingAt offset: Int, count: Int) throws -> [UInt32] {
        var trackIDs: [UInt32] = []
        var cursor = offset
        for _ in 0..<count {
            try reader.expectTag("mhip", at: cursor)
            trackIDs.append(try reader.uint32(at: cursor + 0x18))
            cursor += try reader.recordLength(at: cursor)
        }
        return trackIDs
    }
}
