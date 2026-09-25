import AVFoundation
import ImageIO

/// Decodes the first embedded cover (`covr`) from an .m4a file.
nonisolated struct CoverArtReader: Sendable {
    @concurrent
    func read(_ url: URL) async throws -> CoverArt? {
        let items = try await AVURLAsset(url: url).loadMetadata(for: .iTunesMetadata)
        guard let item = AVMetadataItem.metadataItems(from: items, filteredByIdentifier: .iTunesMetadataCoverArt).first,
              let data = try await item.load(.dataValue),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        return CoverArt(image: image, byteCount: data.count)
    }
}
