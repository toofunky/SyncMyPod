import Foundation

nonisolated enum MP4BoxParser {
    static func parse(_ data: Data) throws -> [MP4Box] {
        var boxes: [MP4Box] = []
        var offset = 0
        while offset < data.count {
            let (box, size) = try parseBox(in: data, at: offset)
            boxes.append(box)
            offset += size
        }
        return boxes
    }

    private static func parseBox(in data: Data, at offset: Int) throws -> (MP4Box, Int) {
        guard offset + MP4Box.headerSize <= data.count else { throw TagWriterError.malformedFile("box header") }
        var size = Int(data.readBigEndian(UInt32.self, at: offset))
        let type = FourCC(rawValue: data.readBigEndian(UInt32.self, at: offset + 4))
        var headerSize = MP4Box.headerSize
        if size == 1 {
            size = Int(data.readBigEndian(UInt64.self, at: offset + 8))
            headerSize += 8
        } else if size == 0 {
            size = data.count - offset
        }
        guard size >= headerSize, offset + size <= data.count else {
            throw TagWriterError.malformedFile("\(type) box size")
        }
        let body = data.subdata(in: offset + headerSize..<offset + size)
        return (try box(type, body: body), size)
    }

    private static func box(_ type: FourCC, body: Data) throws -> MP4Box {
        guard FourCC.mp4Containers.contains(type) else { return MP4Box(type: type, payload: body) }
        let prefixLength = type == .meta && body.count >= 4 && isFullBox(meta: body) ? 4 : 0
        return MP4Box(type: type, prefix: body.prefix(prefixLength),
                      children: try parse(body.subdata(in: prefixLength..<body.count)))
    }

    /// iTunes writes `meta` as a full box, QuickTime as a plain one; a plain one starts with a child's header.
    private static func isFullBox(meta body: Data) -> Bool {
        FourCC(rawValue: body.readBigEndian(UInt32.self, at: 4)) != .hdlr
    }
}
