import Foundation

/// Reads the metadata blocks at the start of a FLAC file, leaving out padding.
nonisolated enum FLACMetadataParser {
    static func parse(_ handle: FileHandle) throws -> FLACMetadata {
        try handle.seek(toOffset: 0)
        guard try read(FLACMetadata.marker.count, from: handle) == FLACMetadata.marker else {
            throw TagWriterError.malformedFile("no fLaC marker")
        }
        var blocks: [FLACMetadataBlock] = []
        var length = FLACMetadata.marker.count
        var isLast = false
        while !isLast {
            let header = try read(FLACMetadataBlock.headerLength, from: handle)
            isLast = header[header.startIndex] & 0x80 != 0
            let type = header[header.startIndex] & 0x7F
            let bodyLength = Int(header.readBigEndian(UInt32.self, at: 0) & 0x00FF_FFFF)
            let body = try read(bodyLength, from: handle)
            if type != FLACMetadataBlock.padding { blocks.append(FLACMetadataBlock(type: type, body: body)) }
            length += header.count + bodyLength
        }
        guard blocks.first?.type == FLACMetadataBlock.streamInfo else {
            throw TagWriterError.malformedFile("no stream info block")
        }
        return FLACMetadata(blocks: blocks, existingLength: length)
    }

    private static func read(_ count: Int, from handle: FileHandle) throws -> Data {
        guard count > 0 else { return Data() }
        guard let data = try handle.read(upToCount: count), data.count == count else {
            throw TagWriterError.unexpectedEndOfFile
        }
        return data
    }
}
