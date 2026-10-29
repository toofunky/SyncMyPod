import CryptoKit
import Foundation

/// Appends rendered thumbnails to the `.ithmb` files, storing identical covers only once per session.
nonisolated struct ArtworkPixelStore {
    let directoryURL: URL

    private var originalSizes: [UInt32: UInt64] = [:]
    private var storedByDigest: [Data: [ArtworkThumbnail]] = [:]

    init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }

    /// Returns where the renders are stored: an identical cover from this session, a `candidate`
    /// already on the iPod whose pixels match byte for byte, or newly appended data.
    mutating func store(_ renders: [RenderedArtwork], reusing candidates: [[ArtworkThumbnail]] = []) throws
        -> [ArtworkThumbnail] {
        let digest = Data(SHA256.hash(data: renders.reduce(Data()) { $0 + $1.pixels }))
        if let stored = storedByDigest[digest] { return stored }
        let thumbnails = try candidates.first { matches($0, renders) } ?? renders.map { try append($0) }
        storedByDigest[digest] = thumbnails
        return thumbnails
    }

    /// Truncates every file this store appended to back to its size before the session.
    func rollBack() {
        for (formatID, size) in originalSizes {
            let url = directoryURL.appending(path: "F\(formatID)_1.ithmb")
            guard let handle = try? FileHandle(forWritingTo: url) else { continue }
            try? handle.truncate(atOffset: size)
            try? handle.close()
        }
    }

    private func matches(_ candidate: [ArtworkThumbnail], _ renders: [RenderedArtwork]) -> Bool {
        candidate.count == renders.count && renders.allSatisfy { render in
            candidate.contains { thumbnail in
                thumbnail.format == render.format && thumbnail.horizontalPadding == render.horizontalPadding
                    && thumbnail.verticalPadding == render.verticalPadding && pixels(at: thumbnail) == render.pixels
            }
        }
    }

    private func pixels(at thumbnail: ArtworkThumbnail) -> Data? {
        let url = directoryURL.appending(path: thumbnail.format.fileName, directoryHint: .notDirectory)
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        guard (try? handle.seek(toOffset: UInt64(thumbnail.offset))) != nil else { return nil }
        return try? handle.read(upToCount: thumbnail.format.byteCount)
    }

    private mutating func append(_ render: RenderedArtwork) throws -> ArtworkThumbnail {
        let url = directoryURL.appending(path: render.format.fileName, directoryHint: .notDirectory)
        if !FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try Data().write(to: url)
        }
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        let offset = try handle.seekToEnd()
        if originalSizes[render.format.id] == nil { originalSizes[render.format.id] = offset }
        try handle.write(contentsOf: render.pixels)
        try handle.synchronize()
        return ArtworkThumbnail(format: render.format, offset: UInt32(offset),
                                horizontalPadding: render.horizontalPadding, verticalPadding: render.verticalPadding)
    }
}
