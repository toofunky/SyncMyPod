import Foundation

nonisolated extension FourCC {
    static let moov = FourCC("moov")
    static let trak = FourCC("trak")
    static let mdia = FourCC("mdia")
    static let minf = FourCC("minf")
    static let stbl = FourCC("stbl")
    static let stco = FourCC("stco")
    static let co64 = FourCC("co64")
    static let udta = FourCC("udta")
    static let meta = FourCC("meta")
    static let hdlr = FourCC("hdlr")
    static let ilst = FourCC("ilst")
    static let data = FourCC("data")
    static let free = FourCC("free")
    static let skip = FourCC("skip")

    static let songName = FourCC("©nam")
    static let artist = FourCC("©ART")
    static let album = FourCC("©alb")
    static let albumArtist = FourCC("aART")
    static let userGenre = FourCC("©gen")
    static let standardGenre = FourCC("gnre")
    static let releaseDate = FourCC("©day")
    static let trackNumber = FourCC("trkn")
    static let discNumber = FourCC("disk")
    static let coverArt = FourCC("covr")

    /// Boxes on the paths to `ilst` and to the chunk offset tables, which get parsed into children.
    static let mp4Containers: Set<FourCC> = [.moov, .trak, .mdia, .minf, .stbl, .udta, .meta, .ilst]
}
