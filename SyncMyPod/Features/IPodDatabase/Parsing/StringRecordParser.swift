import Foundation

nonisolated struct StringRecordParser {
    private static let utf8Encoding: UInt32 = 2

    let reader: BinaryReader

    /// Parses `count` consecutive `mhod` records, keeping the string ones and skipping the rest.
    func parseAll(startingAt offset: Int,
                  count: Int) throws -> (values: [ITunesStringField: String], end: Int) {
        var values: [ITunesStringField: String] = [:]
        var cursor = offset
        for _ in 0..<count {
            if let entry = try parse(at: cursor) {
                values[entry.field] = entry.value
            }
            cursor += try reader.recordLength(at: cursor)
        }
        return (values, cursor)
    }

    func parse(at offset: Int) throws -> (field: ITunesStringField, value: String)? {
        try reader.expectTag("mhod", at: offset)
        guard let field = ITunesStringField(rawValue: try reader.uint32(at: offset + 0x0C)) else {
            return nil
        }
        let encoding = try reader.uint32(at: offset + 0x18)
        let length = try reader.int(at: offset + 0x1C)
        let bytes = try reader.bytes(at: offset + 0x28, count: length)
        let value = encoding == Self.utf8Encoding
            ? String(decoding: bytes, as: UTF8.self)
            : String(data: bytes, encoding: .utf16LittleEndian)
        return value.map { (field, $0) }
    }
}
