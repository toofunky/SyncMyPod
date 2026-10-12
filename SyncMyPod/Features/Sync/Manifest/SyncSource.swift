import Foundation

/// What a library file looked like when it was synced, for noticing later edits.
nonisolated struct SyncSource: Codable, Equatable, Sendable {
    let fileSize: Int
    let modificationDate: Date
    let artworkFingerprint: String?
    /// `true` when the synced tags moved the artist into the title; `nil` otherwise, as in older manifests.
    var preservedAlbumArtist: Bool?
    /// `true` when the copy has lyrics; `nil` otherwise, so older tracks with lyrics get rewritten once.
    var hasLyrics: Bool?
    /// The modification date of the lyric file embedded in the copy; `nil` when none was.
    var lyricsSidecarDate: Date?
    /// The size a player's copy had its embedded artwork scaled to fit; `nil` when it was copied as it is.
    var artworkPixelLimit: Int?
}
