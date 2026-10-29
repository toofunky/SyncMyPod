import Foundation

nonisolated struct RenderedArtwork: Equatable, Sendable {
    let format: ArtworkFormat
    /// Row-major RGB565 little-endian pixels, `format.byteCount` long.
    let pixels: Data
    /// Blank space on each side when the cover isn't the format's shape.
    let horizontalPadding: Int
    let verticalPadding: Int
}
