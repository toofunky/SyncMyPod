import AVFoundation
import ImageIO

/// Decodes the embedded cover scaled down to `maxPixelSize`, so grids never hold full-size images.
nonisolated struct CoverArtThumbnailReader: Sendable {
    let maxPixelSize: Int

    @concurrent
    func read(_ url: URL) async throws -> CoverArt? {
        let items = try await AVURLAsset(url: url).load(.metadata)
        guard let item = items.coverArt,
              let data = try await item.load(.dataValue),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else { return nil }
        return CoverArt(image: image, byteCount: data.count)
    }

    private var thumbnailOptions: CFDictionary {
        [kCGImageSourceCreateThumbnailFromImageAlways: true,
         kCGImageSourceCreateThumbnailWithTransform: true,
         kCGImageSourceThumbnailMaxPixelSize: maxPixelSize] as CFDictionary
    }
}
