import Foundation

/// Parses an iTunesDB or ArtworkDB into an `ITunesDBRecord` tree that serializes back byte for byte.
nonisolated struct ITunesDBRecordParser {
    private let reader: BinaryReader
    private let layout: RecordTreeLayout

    init(data: Data, layout: RecordTreeLayout = .iTunesDB) {
        reader = BinaryReader(data: data)
        self.layout = layout
    }

    func parse() throws -> ITunesDBRecord {
        try reader.expectTag(layout.rootTag, at: 0)
        let (root, end) = try parseRecord(at: 0)
        guard end == reader.count else { throw ITunesDBError.invalidLength(offset: 0) }
        return root
    }

    private func parseRecord(at offset: Int) throws -> (ITunesDBRecord, end: Int) {
        let tag = try reader.tag(at: offset)
        let headerLength = try reader.int(at: offset + 0x04)
        let header = Data(try reader.bytes(at: offset, count: headerLength))
        if layout.listTags.contains(tag) {
            return try parseList(header: header, at: offset)
        }
        let end = offset + (try reader.recordLength(at: offset))
        guard offset + headerLength <= end else { throw ITunesDBError.invalidLength(offset: offset) }
        let body = layout.containerTags.contains(tag)
            ? try parseContainerBody(from: offset + headerLength, to: end)
            : .opaque(Data(try reader.bytes(at: offset + headerLength, count: end - offset - headerLength)))
        return (ITunesDBRecord(header: header, body: body), end)
    }

    private func parseList(header: Data, at offset: Int) throws -> (ITunesDBRecord, end: Int) {
        var cursor = offset + header.count
        var children: [ITunesDBRecord] = []
        for _ in 0..<(try reader.int(at: offset + 0x08)) {
            let (child, end) = try parseRecord(at: cursor)
            children.append(child)
            cursor = end
        }
        return (ITunesDBRecord(header: header, body: .list(children)), cursor)
    }

    private func parseContainerBody(from start: Int, to end: Int) throws -> ITunesDBRecordBody {
        var cursor = start
        var children: [ITunesDBRecord] = []
        while cursor < end, try isKnownTag(at: cursor, before: end) {
            let (child, childEnd) = try parseRecord(at: cursor)
            guard childEnd <= end else { throw ITunesDBError.invalidLength(offset: cursor) }
            children.append(child)
            cursor = childEnd
        }
        return .container(children, trailer: Data(try reader.bytes(at: cursor, count: end - cursor)))
    }

    private func isKnownTag(at offset: Int, before end: Int) throws -> Bool {
        guard offset + 12 <= end else { return false }
        return layout.isKnown(try reader.tag(at: offset))
    }
}
