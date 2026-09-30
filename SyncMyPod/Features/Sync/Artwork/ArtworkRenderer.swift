import CoreGraphics
import Foundation

/// Scales a cover to fit an `ArtworkFormat`, centred on a white background, and packs it as RGB565.
nonisolated enum ArtworkRenderer {
    private static let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

    static func render(_ image: CGImage, as format: ArtworkFormat) -> RenderedArtwork? {
        guard let context = makeContext(for: format) else { return nil }
        let frame = fittedFrame(for: image, in: format)
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: format.width, height: format.height))
        context.interpolationQuality = .high
        context.draw(image, in: frame)
        guard let data = context.data else { return nil }
        let buffer = UnsafeRawBufferPointer(start: data, count: context.bytesPerRow * format.height)
        return RenderedArtwork(format: format,
                               pixels: RGB565Packer.pack(rgbx: buffer, width: format.width, height: format.height,
                                                         rowPixels: format.rowPixels),
                               horizontalPadding: Int(frame.minX), verticalPadding: Int(frame.minY))
    }

    static func fittedFrame(for image: CGImage, in format: ArtworkFormat) -> CGRect {
        let scale = min(Double(format.width) / Double(image.width), Double(format.height) / Double(image.height))
        let width = min(format.width, max(1, Int((Double(image.width) * scale).rounded())))
        let height = min(format.height, max(1, Int((Double(image.height) * scale).rounded())))
        return CGRect(x: (format.width - width) / 2, y: (format.height - height) / 2, width: width, height: height)
    }

    private static func makeContext(for format: ArtworkFormat) -> CGContext? {
        guard let sRGB = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        return CGContext(data: nil, width: format.width, height: format.height, bitsPerComponent: 8,
                         bytesPerRow: format.width * 4, space: sRGB, bitmapInfo: bitmapInfo)
    }
}
