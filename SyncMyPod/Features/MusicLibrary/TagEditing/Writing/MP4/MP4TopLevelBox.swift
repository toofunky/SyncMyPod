import Foundation

/// Where a top-level box sits in a file, read without loading its contents.
nonisolated struct MP4TopLevelBox: Equatable, Sendable {
    let type: FourCC
    let range: Range<Int>

    static func scan(_ handle: FileHandle, fileSize: Int) throws -> [MP4TopLevelBox] {
        var boxes: [MP4TopLevelBox] = []
        var offset = 0
        while offset + MP4Box.headerSize <= fileSize {
            try handle.seek(toOffset: UInt64(offset))
            let header = try handle.read(upToCount: 16) ?? Data()
            guard header.count >= MP4Box.headerSize else { throw TagWriterError.unexpectedEndOfFile }
            let size = boxSize(header: header, offset: offset, fileSize: fileSize)
            guard size >= MP4Box.headerSize, offset + size <= fileSize else {
                throw TagWriterError.malformedFile("top-level box size")
            }
            boxes.append(MP4TopLevelBox(type: FourCC(rawValue: header.readBigEndian(UInt32.self, at: 4)),
                                        range: offset..<offset + size))
            offset += size
        }
        return boxes
    }

    private static func boxSize(header: Data, offset: Int, fileSize: Int) -> Int {
        switch header.readBigEndian(UInt32.self, at: 0) {
        case 0: fileSize - offset
        case 1: Int(header.readBigEndian(UInt64.self, at: 8))
        case let size: Int(size)
        }
    }
}
