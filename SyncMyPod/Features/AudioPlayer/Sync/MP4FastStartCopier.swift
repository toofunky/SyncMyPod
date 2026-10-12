import Foundation

/// Copies an .m4a with its `moov` box moved in front of the audio, for players such as Sonos that read a
/// song's tags from the start of the file over the network and skip songs whose `moov` comes last. The
/// audio is copied unchanged; only the chunk offsets pointing at it move.
nonisolated struct MP4FastStartCopier {
    static let fileExtensions: Set<String> = ["m4a", "m4b", "mp4"]
    /// Room after `moov` so retagging the copy fits in place.
    private static let padding = 2_048
    private static let copyChunkSize = 1 << 20

    /// Where the audio starts, the `moov` box, and `moov` with the `free` padding after it.
    private typealias Layout = (media: Int, moov: Range<Int>, region: Range<Int>)

    /// Writes nothing and returns `false` when `source` isn't an MP4 whose `moov` follows all its audio,
    /// or can't be read as one, so the caller copies it as it is.
    func copy(_ source: URL, to destination: URL) throws -> Bool {
        guard Self.fileExtensions.contains(source.pathExtension.lowercased()) else { return false }
        let input = try FileHandle(forReadingFrom: source)
        defer { try? input.close() }
        let fileSize = Int(try input.seekToEnd())
        guard let layout = try? lateMovie(in: input, fileSize: fileSize),
              var moov = try? MP4BoxParser.parse(read(layout.moov, from: input)).first,
              (try? MP4ChunkOffsetShifter.shift(&moov, by: moov.size + Self.padding, from: layout.media)) != nil
        else { return false }
        try write(moov, from: input, layout: layout, fileSize: fileSize, to: destination)
        return true
    }

    /// `nil` unless `moov` comes after every `mdat`.
    private func lateMovie(in handle: FileHandle, fileSize: Int) throws -> Layout? {
        let boxes = try MP4TopLevelBox.scan(handle, fileSize: fileSize)
        guard let moovIndex = boxes.firstIndex(where: { $0.type == .moov }),
              let mediaIndex = boxes.firstIndex(where: { $0.type == .mdat }), mediaIndex < moovIndex
        else { return nil }
        let after = boxes[(moovIndex + 1)...]
        guard !after.contains(where: { $0.type == .mdat }) else { return nil }
        let moov = boxes[moovIndex].range
        let padding = after.prefix { $0.type == .free || $0.type == .skip }
        let region = moov.lowerBound..<(padding.last?.range.upperBound ?? moov.upperBound)
        return (boxes[mediaIndex].range.lowerBound, moov, region)
    }

    private func write(_ moov: MP4Box, from input: FileHandle, layout: Layout, fileSize: Int,
                       to destination: URL) throws {
        try Data().write(to: destination)
        let output = try FileHandle(forWritingTo: destination)
        defer { try? output.close() }
        try copy(0..<layout.media, from: input, to: output)
        try output.write(contentsOf: moov.serialized() + MP4Box.free(size: Self.padding).serialized())
        try copy(layout.media..<layout.region.lowerBound, from: input, to: output)
        try copy(layout.region.upperBound..<fileSize, from: input, to: output)
    }

    private func read(_ range: Range<Int>, from handle: FileHandle) throws -> Data {
        try handle.seek(toOffset: UInt64(range.lowerBound))
        guard let data = try handle.read(upToCount: range.count), data.count == range.count else {
            throw TagWriterError.unexpectedEndOfFile
        }
        return data
    }

    private func copy(_ range: Range<Int>, from input: FileHandle, to output: FileHandle) throws {
        try input.seek(toOffset: UInt64(range.lowerBound))
        var remaining = range.count
        while remaining > 0 {
            guard let chunk = try input.read(upToCount: min(remaining, Self.copyChunkSize)), !chunk.isEmpty else {
                throw TagWriterError.unexpectedEndOfFile
            }
            try output.write(contentsOf: chunk)
            remaining -= chunk.count
        }
    }
}
