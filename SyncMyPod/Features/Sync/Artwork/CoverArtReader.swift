import AVFoundation
import ImageIO

/// Decodes the first embedded cover (`covr` in .m4a, `APIC` in .mp3, `PICTURE` in .flac).
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
}
