import Foundation

/// A thumbnail size the firmware displays, stored as RGB565 in `F<id>_1.ithmb`.
nonisolated struct ArtworkFormat: Equatable, Hashable, Sendable {
    static let bytesPerPixel = 2

    /// iPod with video (5G/5.5G): list thumbnail and Now Playing cover.
    static let videoIPod = [
        ArtworkFormat(id: 1028, width: 100, height: 100),
        ArtworkFormat(id: 1029, width: 200, height: 200)
    ]

    /// iPod classic (6G–7G), per libgpod's device table: list, browse, and Now Playing sizes.
    static let classicIPod = [
        ArtworkFormat(id: 1061, width: 56, height: 56),
        ArtworkFormat(id: 1055, width: 128, height: 128),
        ArtworkFormat(id: 1068, width: 128, height: 128),
        ArtworkFormat(id: 1060, width: 320, height: 320)
    ]

    let id: UInt32
    let width: Int
    let height: Int

    var byteCount: Int { width * height * Self.bytesPerPixel }
    var fileName: String { "F\(id)_1.ithmb" }
}
