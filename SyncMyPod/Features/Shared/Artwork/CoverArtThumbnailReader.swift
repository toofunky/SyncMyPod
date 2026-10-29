import AVFoundation
import ImageIO

/// Decodes the embedded cover scaled down to `maxPixelSize`, so grids never hold full-size images. A cover
/// image file, such as an audiobook folder's cover.jpg, is decoded the same way.
nonisolated struct CoverArtThumbnailReader: Sendable {
    let maxPixelSize: Int

    @concurrent
    func read(_ url: URL) async throws -> CoverArt? {
        if CoverArtReader.isImageFile(url) { return readImageFile(url) }
        let items = try await AVURLAsset(url: url).load(.metadata)
        guard let item = items.coverArt,
              let data = try await item.load(.dataValue),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else { return nil }
        return CoverArt(image: image, byteCount: data.count)
    }

    private func readImageFile(_ url: URL) -> CoverArt? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else { return nil }
        let byteCount = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        return CoverArt(image: image, byteCount: byteCount)
    }

    private var thumbnailOptions: CFDictionary {
        [kCGImageSourceCreateThumbnailFromImageAlways: true,
         kCGImageSourceCreateThumbnailWithTransform: true,
         kCGImageSourceThumbnailMaxPixelSize: maxPixelSize] as CFDictionary
    }
}
