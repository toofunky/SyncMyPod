import Foundation

/// Moves every `stco`/`co64` entry at or past `threshold` by `delta`, for when the bytes before the
/// media data change length.
nonisolated enum MP4ChunkOffsetShifter {
    private static let entriesOffset = 8

    static func shift(_ box: inout MP4Box, by delta: Int, from threshold: Int) throws {
        switch box.type {
        case .stco: box.payload = try shifted(box.payload, entrySize: 4, by: delta, from: threshold)
        case .co64: box.payload = try shifted(box.payload, entrySize: 8, by: delta, from: threshold)
        default:
            guard var children = box.children else { return }
            for index in children.indices { try shift(&children[index], by: delta, from: threshold) }
            box.children = children
        }
    }

    private static func shifted(_ payload: Data, entrySize: Int, by delta: Int, from threshold: Int) throws -> Data {
        var payload = Data(payload)
        let count = Int(payload.readBigEndian(UInt32.self, at: 4))
        guard entriesOffset + count * entrySize <= payload.count else {
            throw TagWriterError.malformedFile("chunk offset table")
        }
        for index in 0..<count {
            let position = entriesOffset + index * entrySize
            let offset = entrySize == 4 ? Int(payload.readBigEndian(UInt32.self, at: position))
                                        : Int(payload.readBigEndian(UInt64.self, at: position))
            guard offset >= threshold else { continue }
            if entrySize == 8 {
                payload.writeBigEndian(UInt64(offset + delta), at: position)
            } else {
                guard let moved = UInt32(exactly: offset + delta) else { throw TagWriterError.chunkOffsetOverflow }
                payload.writeBigEndian(moved, at: position)
            }
        }
        return payload
    }
}
