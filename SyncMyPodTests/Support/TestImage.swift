import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Generates sRGB test images whose top and bottom halves can differ in color.
nonisolated enum TestImage {
    static func make(width: Int, height: Int, top: CGColor, bottom: CGColor? = nil) -> CGImage {
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(bottom ?? top)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height / 2))
        context.setFillColor(top)
        context.fill(CGRect(x: 0, y: height / 2, width: width, height: height - height / 2))
        return context.makeImage()!
    }

    static func pngData(_ image: CGImage) -> Data {
        data(image, type: .png)
    }

    static func jpegData(_ image: CGImage) -> Data {
        data(image, type: .jpeg)
    }

    /// Width, height and type identifier of the image at `url`.
    static func dimensions(at url: URL) -> (width: Int, height: Int, type: String)? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              let type = CGImageSourceGetType(source) else { return nil }
        return (width, height, type as String)
    }

    private static func data(_ image: CGImage, type: UTType) -> Data {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        return data as Data
    }

    static func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> CGColor {
        CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: [red, green, blue, 1])!
    }
}
