import Foundation

/// One track as the nano's SQLite library needs it, read from an `mhit` record.
nonisolated struct NanoLibraryItem: Equatable, Sendable {
    let pid: UInt64
    let strings: [ITunesStringField: String]
    let mediaType: UInt32
    let isCompilation: Bool
    let rating: Int
    let year: Int
    let durationMS: Int
    let trackNumber: Int
    let trackCount: Int
    let discNumber: Int
    let discCount: Int
    let bpm: Int
    let bitrate: Int
    let sampleRate: Int
    let fileSize: Int
    let fileTypeCode: UInt32
    let playCount: Int
    let skipCount: Int
    let dateLastSkipped: UInt32
    let bookmarkMS: Int
    let dateModified: UInt32
    let dateLastPlayed: UInt32
    let dateAdded: UInt32
    let dateReleased: UInt32
    let volumeNormalization: Int
    let sampleCount: UInt64
    let encoderDelay: Int
    let encoderDrain: Int
    let lastFrameResync: Int
    let artworkID: UInt32
    let albumID: UInt32
    let artistID: UInt32

    func string(_ field: ITunesStringField) -> String? {
        strings[field].flatMap { $0.isEmpty ? nil : $0 }
    }

    /// The artist the album and Artists menus file this track under.
    var albumArtistName: String? { string(.albumArtist) ?? string(.artist) }
}
