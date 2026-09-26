import Foundation

/// Rewrites an `.ithmb` file without the images nothing references any more.
nonisolated struct ArtworkCompactor {
    static let minimumWastedBytes: Int64 = 32 * 1_024 * 1_024
    static let minimumWastedFraction = 0.25
    private static let stagingSuffix = ".syncmypod-compact"

    let directoryURL: URL

    /// Old → new offsets when enough of the file is unreferenced to be worth rewriting.
    func compactionMapping(for format: ArtworkFormat, referenced offsets: Set<UInt32>) -> [UInt32: UInt32]? {
        let fileSize = Int64((try? fileURL(for: format).resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
        let wasted = fileSize - Int64(offsets.count * format.byteCount)
        guard wasted > 0,
              wasted >= Self.minimumWastedBytes || Double(wasted) / Double(fileSize) >= Self.minimumWastedFraction
        else { return nil }
        let sorted = offsets.sorted()
        return Dictionary(uniqueKeysWithValues: sorted.enumerated().map { ($1, UInt32($0 * format.byteCount)) })
    }

    /// Writes the compacted pixels beside the original and returns the staged file.
    func stage(_ format: ArtworkFormat, mapping: [UInt32: UInt32]) throws -> URL {
        let staged = directoryURL.appending(path: format.fileName + Self.stagingSuffix, directoryHint: .notDirectory)
        try Data().write(to: staged)
        let source = try FileHandle(forReadingFrom: fileURL(for: format))
        let destination = try FileHandle(forWritingTo: staged)
        defer {
            try? source.close()
            try? destination.close()
        }
        for (oldOffset, _) in mapping.sorted(by: { $0.value < $1.value }) {
            try source.seek(toOffset: UInt64(oldOffset))
            guard let pixels = try source.read(upToCount: format.byteCount), pixels.count == format.byteCount else {
                throw CocoaError(.fileReadCorruptFile)
            }
            try destination.write(contentsOf: pixels)
        }
        try destination.synchronize()
        return staged
    }

    /// Atomically replaces the format's file with its staged copy.
    func commit(_ staged: URL, for format: ArtworkFormat) throws {
        guard rename(staged.path(percentEncoded: false), fileURL(for: format).path(percentEncoded: false)) == 0 else {
            throw CocoaError(.fileWriteUnknown)
        }
    }

    private func fileURL(for format: ArtworkFormat) -> URL {
        directoryURL.appending(path: format.fileName, directoryHint: .notDirectory)
    }
}
