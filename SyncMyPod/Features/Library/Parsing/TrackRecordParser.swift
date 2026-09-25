import Foundation

nonisolated struct TrackRecordParser {
    private static let mediaTypeHeaderLength = 0xD4

    let reader: BinaryReader

    func parse(at offset: Int) throws -> ITunesTrack {
        try reader.expectTag("mhit", at: offset)
        let headerLength = try reader.int(at: offset + 0x04)
        let stringCount = try reader.int(at: offset + 0x0C)
        let strings = try StringRecordParser(reader: reader)
            .parseAll(startingAt: offset + headerLength, count: stringCount)
        return try makeTrack(at: offset, headerLength: headerLength, strings: strings.values)
    }

    private func makeTrack(at offset: Int, headerLength: Int,
                           strings: [ITunesStringField: String]) throws -> ITunesTrack {
        let hasMediaType = headerLength >= Self.mediaTypeHeaderLength
        return try ITunesTrack(
            id: reader.uint32(at: offset + 0x10),
            databaseID: reader.uint64(at: offset + 0x70),
            strings: strings,
            duration: TimeInterval(reader.uint32(at: offset + 0x28)) / 1000,
            fileSize: reader.int(at: offset + 0x24),
            trackNumber: reader.int(at: offset + 0x2C),
            trackCount: reader.int(at: offset + 0x30),
            discNumber: reader.int(at: offset + 0x5C),
            discCount: reader.int(at: offset + 0x60),
            year: reader.int(at: offset + 0x34),
            bitrate: reader.int(at: offset + 0x38),
            sampleRate: Int(reader.uint32(at: offset + 0x3C) >> 16),
            rating: Int(reader.uint8(at: offset + 0x1F)),
            playCount: reader.int(at: offset + 0x50),
            mediaType: hasMediaType ? reader.uint32(at: offset + 0xD0) : nil,
            dateAdded: reader.macDate(at: offset + 0x68),
            lastPlayed: reader.macDate(at: offset + 0x58),
            lastModified: reader.macDate(at: offset + 0x20)
        )
    }
}
