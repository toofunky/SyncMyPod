import Foundation

/// What a library file looked like when it was synced, for noticing later edits.
nonisolated struct SyncSource: Codable, Equatable, Sendable {
    let fileSize: Int
    let modificationDate: Date
    let artworkFingerprint: String?
    /// `true` when the synced tags moved the artist into the title; `nil` otherwise, as in older manifests.
    var preservedAlbumArtist: Bool?
}
