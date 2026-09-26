import Foundation

/// Rewrites the `moov` box of an .m4a with new tags. It absorbs size changes into following `free`
/// boxes when it can, rewrites in place when `moov` is last, and otherwise shifts the chunk offsets and
/// rewrites the file with padding so later edits fit in place.
nonisolated struct MP4TagWriter {
    private static let padding = 2_048

    func write(_ changes: TagChanges, to url: URL) throws {
        let (region, fileSize, moovData) = try readMovieRegion(of: url)
        guard var moov = try MP4BoxParser.parse(moovData).first else { throw TagWriterError.missingMovieBox }
        MP4MetadataEditor.apply(changes, to: &moov)
        let replacement = try layOut(&moov, replacing: region, fileSize: fileSize)
        try FileRegionReplacer(url: url).replace(region, with: replacement)
    }

    /// The `moov` box plus any `free`/`skip` boxes right after it, and the `moov` bytes.
    private func readMovieRegion(of url: URL) throws -> (Range<Int>, Int, Data) {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let fileSize = Int(try handle.seekToEnd())
        let boxes = try MP4TopLevelBox.scan(handle, fileSize: fileSize)
        guard let index = boxes.firstIndex(where: { $0.type == .moov }) else { throw TagWriterError.missingMovieBox }
        let moov = boxes[index].range
        let padding = boxes[(index + 1)...].prefix { $0.type == .free || $0.type == .skip }
        try handle.seek(toOffset: UInt64(moov.lowerBound))
        guard let data = try handle.read(upToCount: moov.count), data.count == moov.count else {
            throw TagWriterError.unexpectedEndOfFile
        }
        return (moov.lowerBound..<(padding.last?.range.upperBound ?? moov.upperBound), fileSize, data)
    }

    private func layOut(_ moov: inout MP4Box, replacing region: Range<Int>, fileSize: Int) throws -> Data {
        let spare = region.count - moov.size
        if spare == 0 || spare >= MP4Box.headerSize {
            return moov.serialized() + (spare > 0 ? MP4Box.free(size: spare).serialized() : Data())
        }
        if region.upperBound == fileSize { return moov.serialized() }
        let newSize = moov.size + Self.padding
        try MP4ChunkOffsetShifter.shift(&moov, by: newSize - region.count, from: region.upperBound)
        return moov.serialized() + MP4Box.free(size: Self.padding).serialized()
    }
}
