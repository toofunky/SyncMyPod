import Foundation
import ImageIO

/// Scales a cover image down to fit a square, keeping its proportions and its JPEG or PNG format.
/// Images that already fit are left untouched, so covers are never enlarged or recompressed needlessly.
nonisolated enum CoverResizer {
    private static let jpegQuality = 0.9

    static func fit(imageAt url: URL, within pixelLimit: Int) throws {
        guard let data = try? Data(contentsOf: url) else { throw CoverResizeError.unreadableImage }
        guard let resized = try fitted(data, within: pixelLimit) else { return }
        let staged = url.deletingLastPathComponent().appending(path: ".syncmypod-\(UUID().uuidString).tmp")
        do {
            try resized.write(to: staged)
            _ = try FileManager.default.replaceItemAt(url, withItemAt: staged)
        } catch {
            try? FileManager.default.removeItem(at: staged)
            throw CoverResizeError.unwritableImage
        }
    }

    /// The encoded image scaled down to fit, in its own format, or `nil` when it already fits.
    static func fitted(_ data: Data, within pixelLimit: Int) throws -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil), let type = CGImageSourceGetType(source),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            throw CoverResizeError.unreadableImage
        }
        guard max(width, height) > pixelLimit else { return nil }
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                        kCGImageSourceCreateThumbnailWithTransform: true,
                                        kCGImageSourceThumbnailMaxPixelSize: pixelLimit]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw CoverResizeError.unreadableImage
        }
        return try encoded(image, as: type)
    }

    private static func encoded(_ image: CGImage, as type: CFString) throws -> Data {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, type, 1, nil) else {
            throw CoverResizeError.unwritableImage
        }
        let properties = [kCGImageDestinationLossyCompressionQuality: jpegQuality] as CFDictionary
        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else { throw CoverResizeError.unwritableImage }
        return output as Data
    }
}
