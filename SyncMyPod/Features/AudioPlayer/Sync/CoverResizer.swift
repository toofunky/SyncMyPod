import Foundation
import ImageIO

/// Scales a cover image down to fit a square, keeping its proportions and its JPEG or PNG format.
nonisolated enum CoverResizer {
    private static let jpegQuality = 0.9

    /// Leaves images that already fit untouched, so covers are never enlarged or recompressed needlessly.
    static func fit(imageAt url: URL, within pixelLimit: Int) throws {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil), let type = CGImageSourceGetType(source),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            throw CoverResizeError.unreadableImage
        }
        guard max(width, height) > pixelLimit else { return }
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                        kCGImageSourceCreateThumbnailWithTransform: true,
                                        kCGImageSourceThumbnailMaxPixelSize: pixelLimit]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw CoverResizeError.unreadableImage
        }
        try write(image, as: type, to: url)
    }

    private static func write(_ image: CGImage, as type: CFString, to url: URL) throws {
        let resized = url.deletingLastPathComponent().appending(path: ".syncmypod-\(UUID().uuidString).tmp")
        guard let destination = CGImageDestinationCreateWithURL(resized as CFURL, type, 1, nil) else {
            throw CoverResizeError.unwritableImage
        }
        let properties = [kCGImageDestinationLossyCompressionQuality: jpegQuality] as CFDictionary
        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else {
            try? FileManager.default.removeItem(at: resized)
            throw CoverResizeError.unwritableImage
        }
        _ = try FileManager.default.replaceItemAt(url, withItemAt: resized)
    }
}
