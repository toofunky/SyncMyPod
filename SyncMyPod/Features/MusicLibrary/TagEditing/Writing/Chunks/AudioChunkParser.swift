import Foundation

/// Lists the top-level chunks of a WAV or AIFF file without reading their bodies.
nonisolated enum AudioChunkParser {
    static func parse(_ handle: FileHandle) throws -> AudioChunkLayout {
        let fileSize = Int(try handle.seekToEnd())
        try handle.seek(toOffset: 0)
        let header = try handle.read(upToCount: AudioChunkFormat.headerLength) ?? Data()
        guard let format = AudioChunkFormat(header: header) else {
            throw TagWriterError.malformedFile("not a WAV or AIFF file")
        }
        let end = min(fileSize, AudioChunk.headerLength + format.size(in: header, at: 4))
        var chunks: [AudioChunk] = []
        var offset = AudioChunkFormat.headerLength
        while offset + AudioChunk.headerLength <= end {
            try handle.seek(toOffset: UInt64(offset))
            let chunkHeader = try handle.read(upToCount: AudioChunk.headerLength) ?? Data()
            let chunk = AudioChunk(id: String(decoding: chunkHeader.prefix(4), as: UTF8.self), offset: offset,
                                   size: format.size(in: chunkHeader, at: 4))
            guard chunk.bodyOffset + chunk.size <= end else { break }
            chunks.append(chunk)
            offset += chunk.paddedLength
        }
        return AudioChunkLayout(format: format, chunks: chunks, end: end)
    }
}
