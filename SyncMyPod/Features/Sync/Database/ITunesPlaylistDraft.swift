import Foundation

/// A playlist to write to the iTunesDB, its songs given by database ID in play order.
nonisolated struct ITunesPlaylistDraft: Equatable, Sendable {
    let id: UInt64
    let name: String
    let createdAt: Date
    let databaseIDs: [UInt64]
}
