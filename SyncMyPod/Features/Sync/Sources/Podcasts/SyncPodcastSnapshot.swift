import Foundation

/// A podcast's downloaded episodes as a sync plans them, copied off the model like library tracks are.
nonisolated struct SyncPodcastSnapshot: Equatable, Sendable {
    let key: String
    /// Oldest first, so the podcast's playlist plays in the order the episodes came out.
    let playlist: SyncPlaylistRequest

    var name: String { playlist.name }
    var episodes: [SyncRequest] { playlist.tracks }
    var byteCount: Int64 { episodes.reduce(0) { $0 + Int64($1.draft.fileSize) } }
}
