import Foundation

/// Updates the ID3v2 tag that WAV and AIFF files keep in an `id3 ` or `ID3 ` chunk, adding the chunk at the
/// end of the file when there's none. The chunk is overwritten in place when the tag fits in its padding.
nonisolated struct ChunkedID3TagWriter {
    private static let padding = 2_048

    func write(_ changes: TagChanges, to url: URL) throws {
        let (layout, existingTag) = try read(url)
        var tag = existingTag
        ID3TagWriter().apply(changes, to: &tag)
        let existing = layout.id3Chunk
        let room = existing?.size ?? 0
        let fitted = tag.serialized(minimumLength: room)
        let body = fitted.count == room ? fitted : tag.serialized(minimumLength: fitted.count + Self.padding)
        var chunk = layout.format.chunk(id: existing?.id ?? layout.format.id3ChunkID, body: body)
        let range: Range<Int>
        if let existing {
            range = existing.offset..<min(existing.offset + existing.paddedLength, layout.end)
        } else {
            if layout.end % 2 == 1 { chunk.insert(0, at: chunk.startIndex) }
            range = layout.end..<layout.end
        }
        try FileRegionReplacer(url: url).replace(range, with: chunk)
        try writeContainerSize(layout.end + chunk.count - range.count - AudioChunk.headerLength,
                               format: layout.format, to: url)
    }

    private func read(_ url: URL) throws -> (AudioChunkLayout, ID3Tag) {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let layout = try AudioChunkParser.parse(handle)
        guard let chunk = layout.id3Chunk else { return (layout, ID3Tag()) }
        return (layout, try ID3TagParser.parse(handle, at: UInt64(chunk.bodyOffset)))
    }

    private func writeContainerSize(_ size: Int, format: AudioChunkFormat, to url: URL) throws {
        let handle = try FileHandle(forUpdating: url)
        defer { try? handle.close() }
        try handle.seek(toOffset: 4)
        try handle.write(contentsOf: format.encoded(size: size))
    }
}
