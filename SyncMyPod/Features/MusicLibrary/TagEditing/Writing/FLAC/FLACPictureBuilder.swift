import Foundation
import ImageIO

/// Builds FLAC `PICTURE` blocks, whose fields are all big-endian.
nonisolated enum FLACPictureBuilder {
    private static let frontCoverType: UInt32 = 3

    static func frontCover(_ image: Data, type: ArtworkImageType) -> FLACMetadataBlock {
        let size = pixelSize(of: image)
        var body = Data()
        body.appendBigEndian(frontCoverType)
        body.appendBigEndian(UInt32(type.mimeType.utf8.count))
        body.append(Data(type.mimeType.utf8))
        body.appendBigEndian(UInt32(0))
        body.appendBigEndian(size.width)
        body.appendBigEndian(size.height)
        body.appendBigEndian(size.depth)
        body.appendBigEndian(UInt32(0))
        body.appendBigEndian(UInt32(image.count))
        body.append(image)
        return FLACMetadataBlock(type: FLACMetadataBlock.picture, body: body)
    }

    /// Zeros when the image can't be decoded.
    private static func pixelSize(of image: Data) -> (width: UInt32, height: UInt32, depth: UInt32) {
        guard let source = CGImageSourceCreateWithData(image as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return (0, 0, 0) }
        return (UInt32(image.width), UInt32(image.height), UInt32(image.bitsPerPixel))
    }
}
