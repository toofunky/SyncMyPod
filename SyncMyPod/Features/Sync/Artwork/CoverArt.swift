import CoreGraphics
import Foundation

nonisolated struct CoverArt: @unchecked Sendable {
    let image: CGImage
    /// Size of the encoded image embedded in the audio file.
    let byteCount: Int
}
