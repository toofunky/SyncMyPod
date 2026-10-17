import Foundation

/// A playlist to write to the iTunesDB, its songs given by database ID in play order.
nonisolated struct ITunesPlaylistDraft: Equatable, Sendable {
    let id: UInt64
    let name: String
    let createdAt: Date
    let databaseIDs: [UInt64]
    /// For the Podcasts list, each episode's show, parallel to `databaseIDs`; `nil` for other playlists.
    var podcastShows: [String]?

    var isPodcasts: Bool { podcastShows != nil }
}
