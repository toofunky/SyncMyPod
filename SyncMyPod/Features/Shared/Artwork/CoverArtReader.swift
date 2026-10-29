import AVFoundation
import ImageIO

/// Decodes the first embedded cover (`covr` in .m4a, `APIC` in .mp3 and AIFF and WAV ID3 chunks, `PICTURE` in .flac).
nonisolated struct CoverArtReader: Sendable {
    @concurrent
    func read(_ url: URL) async throws -> CoverArt? {
        let items = try await AVURLAsset(url: url).load(.metadata)
        guard let item = items.coverArt,
              let data = try await item.load(.dataValue),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        return CoverArt(image: image, byteCount: data.count)
    }

    /// A cover image file, such as an audiobook folder's cover.jpg, at full size.
    @concurrent
    func readImageFile(_ url: URL) async -> CoverArt? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        let byteCount = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        return CoverArt(image: image, byteCount: byteCount)
    }

    static func isImageFile(_ url: URL) -> Bool {
        ["jpg", "jpeg", "png"].contains(url.pathExtension.lowercased())
    }
}
