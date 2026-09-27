import Foundation

nonisolated extension FourCC {
    static let id3Title = FourCC("TIT2")
    static let id3Artist = FourCC("TPE1")
    static let id3Album = FourCC("TALB")
    static let id3AlbumArtist = FourCC("TPE2")
    static let id3Genre = FourCC("TCON")
    static let id3Composer = FourCC("TCOM")
    static let id3Year = FourCC("TYER")
    static let id3RecordingTime = FourCC("TDRC")
    static let id3Track = FourCC("TRCK")
    static let id3Disc = FourCC("TPOS")
    static let id3Picture = FourCC("APIC")
}
