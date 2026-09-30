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

    /// iPod nano (7G), from the file list in the device's own ArtworkDB. F1016 rows are padded to 58 pixels.
    static let nano7G = [
        ArtworkFormat(id: 1013, width: 50, height: 50),
        ArtworkFormat(id: 1016, width: 57, height: 57, rowPixels: 58),
        ArtworkFormat(id: 1015, width: 58, height: 58),
        ArtworkFormat(id: 1010, width: 240, height: 240)
    ]

    let id: UInt32
    let width: Int
    let height: Int
    /// Pixels stored per row, which some formats pad beyond `width`.
    let rowPixels: Int

    init(id: UInt32, width: Int, height: Int, rowPixels: Int? = nil) {
        self.id = id
        self.width = width
        self.height = height
        self.rowPixels = rowPixels ?? width
    }

    var byteCount: Int { rowPixels * height * Self.bytesPerPixel }
    var fileName: String { "F\(id)_1.ithmb" }
}
