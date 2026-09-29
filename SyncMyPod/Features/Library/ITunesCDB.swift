import Foundation

/// The nano 5G+ database: an uncompressed mhbd header followed by the rest of an iTunesDB as one zlib stream.
nonisolated enum ITunesCDB {
    static let compressionFlagOffset = 0xA8
    private static let totalLengthOffset = 0x08
    private static let minimumHeaderLength = 0xA9
    private static let zlibHeaderLength = 2
    private static let zlibChecksumLength = 4

    static func isCompressed(_ data: Data) -> Bool {
        guard let headerLength = headerLength(of: data) else { return false }
        return data.read(UInt16.self, at: compressionFlagOffset) == 1 && headerLength < data.count
    }

    /// Returns the equivalent uncompressed iTunesDB, or `data` unchanged if it isn't compressed.
    static func decompress(_ data: Data) throws -> Data {
        guard isCompressed(data), let headerLength = headerLength(of: data) else { return data }
        let stream = Data(data.dropFirst(headerLength))
        guard stream.count > zlibHeaderLength + zlibChecksumLength else {
            throw ITunesDBError.truncated(offset: headerLength)
        }
        // Foundation's zlib codec reads raw DEFLATE, so the zlib header and Adler-32 trailer are stripped.
        let deflated = stream.dropFirst(zlibHeaderLength).dropLast(zlibChecksumLength)
        let payload = try (Data(deflated) as NSData).decompressed(using: .zlib) as Data
        var database = Data(data.prefix(headerLength)) + payload
        database.write(UInt32(database.count), at: totalLengthOffset)
        database.write(UInt16(0), at: compressionFlagOffset)
        return database
    }

    private static func headerLength(of data: Data) -> Int? {
        guard data.count >= minimumHeaderLength, data.prefix(4) == Data("mhbd".utf8) else { return nil }
        let length = Int(data.read(UInt32.self, at: 0x04))
        return length >= minimumHeaderLength ? length : nil
    }
}
