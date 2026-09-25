import Foundation

nonisolated struct BinaryReader: Sendable {
    private static let macEpochOffset: TimeInterval = 2_082_844_800

    let data: Data

    var count: Int { data.count }

    func uint8(at offset: Int) throws -> UInt8 { try integer(at: offset) }
    func uint16(at offset: Int) throws -> UInt16 { try integer(at: offset) }
    func uint32(at offset: Int) throws -> UInt32 { try integer(at: offset) }
    func uint64(at offset: Int) throws -> UInt64 { try integer(at: offset) }
    func int(at offset: Int) throws -> Int { Int(try uint32(at: offset)) }

    func bytes(at offset: Int, count length: Int) throws -> Data {
        try ensureAvailable(offset: offset, length: length)
        let start = data.startIndex + offset
        return data[start..<start + length]
    }

    func tag(at offset: Int) throws -> String {
        String(decoding: try bytes(at: offset, count: 4), as: UTF8.self)
    }

    func expectTag(_ expected: String, at offset: Int) throws {
        let found = try tag(at: offset)
        guard found == expected else {
            throw ITunesDBError.unexpectedTag(expected: expected, found: found, offset: offset)
        }
    }

    /// Total size of the record at `offset`, including its children. Not valid for `mhlt`/`mhlp`,
    /// whose third field is an item count.
    func recordLength(at offset: Int) throws -> Int {
        let length = try int(at: offset + 8)
        guard length >= 12, offset + length <= count else { throw ITunesDBError.invalidLength(offset: offset) }
        return length
    }

    func macDate(at offset: Int) throws -> Date? {
        let seconds = try uint32(at: offset)
        guard seconds > 0 else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(seconds) - Self.macEpochOffset)
    }

    private func integer<T: FixedWidthInteger>(at offset: Int) throws -> T {
        try ensureAvailable(offset: offset, length: MemoryLayout<T>.size)
        let raw = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: T.self) }
        return T(littleEndian: raw)
    }

    private func ensureAvailable(offset: Int, length: Int) throws {
        guard offset >= 0, length >= 0, offset + length <= count else {
            throw ITunesDBError.truncated(offset: offset)
        }
    }
}
