import Foundation

/// What a sync would change on a player.
nonisolated struct PlayerSyncPlan: Equatable, Sendable {
    var copies: [PlayerFileCopy] = []
    /// Copies whose library file changed since it was synced.
    var updates: [PlayerFileCopy] = []
    var moves: [PlayerFileMove] = []
    var removals: [PlayerFileRemoval] = []
    /// `nil` leaves the player's playlists alone.
    var playlists: [PlayerPlaylistFile]?
    /// Playlist files written by earlier syncs that are no longer synced.
    var stalePlaylistPaths: [String] = []
    var playlistChangeCount = 0
    var selectedCount = 0

    var isEmpty: Bool { totals.isEmpty }
    var writes: [PlayerFileCopy] { updates + copies }

    var totals: SyncPlanTotals {
        SyncPlanTotals(addCount: copies.count, addBytes: copies.reduce(0) { $0 + $1.byteCount },
                       updateCount: updates.count, updateBytes: updates.reduce(0) { $0 + $1.byteCount },
                       moveCount: moves.count, removeCount: removals.count,
                       removeBytes: removals.reduce(0) { $0 + $1.byteCount },
                       playlistChangeCount: playlistChangeCount, selectedCount: selectedCount)
    }
}
