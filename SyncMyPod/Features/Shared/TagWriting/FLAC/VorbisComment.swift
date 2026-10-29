import Foundation

/// A FLAC Vorbis comment block: a vendor string and `FIELD=value` comments, with little-endian lengths.
/// Field names are case-insensitive and may repeat.
nonisolated struct VorbisComment: Equatable, Sendable {
    var vendor = "SyncMyPod"
    var comments: [String] = []

    init() {}

    init?(data: Data) {
        var offset = 0
        guard let vendor = Self.string(in: data, at: &offset) else { return nil }
        let count = Int(data.read(UInt32.self, at: offset))
        offset += 4
        var comments: [String] = []
        for _ in 0..<count {
            guard let comment = Self.string(in: data, at: &offset) else { return nil }
            comments.append(comment)
        }
        self.vendor = vendor
        self.comments = comments
    }

    /// Replaces every comment named one of `fields` by `FIELD=value`, using the first of `fields`, where the
    /// first stood; `nil` or an empty value removes them.
    mutating func set(_ fields: [String], to value: String?) {
        let names = Set(fields.map { $0.uppercased() })
        let index = comments.firstIndex { names.contains(Self.field(of: $0)) }
        comments.removeAll { names.contains(Self.field(of: $0)) }
        guard let value, !value.isEmpty, let field = fields.first else { return }
        comments.insert("\(field)=\(value)", at: min(index ?? comments.count, comments.count))
    }

    func serialized() -> Data {
        var data = Self.lengthPrefixed(vendor)
        Self.appendLength(comments.count, to: &data)
        for comment in comments { data.append(Self.lengthPrefixed(comment)) }
        return data
    }

    private static func field(of comment: String) -> String {
        String(comment.prefix { $0 != "=" }).uppercased()
    }

    private static func string(in data: Data, at offset: inout Int) -> String? {
        let length = Int(data.read(UInt32.self, at: offset))
        let start = data.startIndex + offset + 4
        guard offset + 4 + length <= data.count else { return nil }
        offset += 4 + length
        return String(decoding: data[start..<start + length], as: UTF8.self)
    }

    private static func lengthPrefixed(_ string: String) -> Data {
        var data = Data()
        appendLength(string.utf8.count, to: &data)
        return data + Data(string.utf8)
    }

    private static func appendLength(_ length: Int, to data: inout Data) {
        Swift.withUnsafeBytes(of: UInt32(length).littleEndian) { data.append(contentsOf: $0) }
    }
}
