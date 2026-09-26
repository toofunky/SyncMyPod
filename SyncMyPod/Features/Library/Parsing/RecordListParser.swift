import Foundation

/// Walks a counted list record (`mhlt`, `mhlp`) whose children follow its header back to back.
nonisolated struct RecordListParser {
    let reader: BinaryReader

    func parse<Record>(listTag: String, at offset: Int,
                       record parseRecord: (Int) throws -> Record) throws -> [Record] {
        try reader.expectTag(listTag, at: offset)
        let recordCount = try reader.int(at: offset + 0x08)
        var cursor = offset + (try reader.int(at: offset + 0x04))
        var records: [Record] = []
        for _ in 0..<recordCount {
            records.append(try parseRecord(cursor))
            cursor += try reader.recordLength(at: cursor)
        }
        return records
    }
}
