import Foundation

/// The embeddable cover formats, recognized from their magic bytes.
nonisolated enum ArtworkImageType: Sendable {
    case jpeg
    case png

    init?(data: Data) {
        let bytes = Array(data.prefix(4))
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
            self = .jpeg
        } else if bytes == [0x89, 0x50, 0x4E, 0x47] {
            self = .png
        } else {
            return nil
        }
    }

    /// The `data` atom's well-known type for `covr` items.
    var mp4DataType: UInt32 {
        switch self {
        case .jpeg: 13
        case .png: 14
        }
    }

    var mimeType: String {
        switch self {
        case .jpeg: "image/jpeg"
        case .png: "image/png"
        }
    }
}
