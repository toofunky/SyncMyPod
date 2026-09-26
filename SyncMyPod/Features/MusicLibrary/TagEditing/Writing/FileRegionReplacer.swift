import Foundation

/// Replaces a byte range of a file, in place when the file's layout allows and otherwise by writing
/// a copy beside it and swapping it in, so a failed write never leaves a half-edited original.
nonisolated struct FileRegionReplacer {
    private static let copyChunkSize = 1 << 20

    let url: URL

    func replace(_ range: Range<Int>, with data: Data) throws {
        let fileSize = try fileSize()
        if data.count == range.count || range.upperBound == fileSize {
            try overwrite(range, with: data, truncating: range.upperBound == fileSize)
        } else {
            try rewrite(range, with: data, fileSize: fileSize)
        }
    }

    private func fileSize() throws -> Int {
        try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
    }

    private func overwrite(_ range: Range<Int>, with data: Data, truncating: Bool) throws {
        let handle = try FileHandle(forUpdating: url)
        defer { try? handle.close() }
        try handle.seek(toOffset: UInt64(range.lowerBound))
        try handle.write(contentsOf: data)
        if truncating { try handle.truncate(atOffset: UInt64(range.lowerBound + data.count)) }
    }

    private func rewrite(_ range: Range<Int>, with data: Data, fileSize: Int) throws {
        let folder = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask,
                                                 appropriateFor: url, create: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let temporary = folder.appending(path: url.lastPathComponent)
        FileManager.default.createFile(atPath: temporary.path(percentEncoded: false), contents: nil)
        let source = try FileHandle(forReadingFrom: url)
        defer { try? source.close() }
        let destination = try FileHandle(forWritingTo: temporary)
        defer { try? destination.close() }
        try copy(0..<range.lowerBound, from: source, to: destination)
        try destination.write(contentsOf: data)
        try copy(range.upperBound..<fileSize, from: source, to: destination)
        try destination.synchronize()
        _ = try FileManager.default.replaceItemAt(url, withItemAt: temporary)
    }

    private func copy(_ range: Range<Int>, from source: FileHandle, to destination: FileHandle) throws {
        try source.seek(toOffset: UInt64(range.lowerBound))
        var remaining = range.count
        while remaining > 0 {
            guard let chunk = try source.read(upToCount: min(remaining, Self.copyChunkSize)),
                  !chunk.isEmpty else { throw TagWriterError.unexpectedEndOfFile }
            try destination.write(contentsOf: chunk)
            remaining -= chunk.count
        }
    }
}
