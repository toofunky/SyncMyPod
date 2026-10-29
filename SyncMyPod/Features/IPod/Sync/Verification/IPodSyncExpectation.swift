import Foundation

/// What a finished sync left in the iPod's database, so a later read can tell whether another app undid it.
nonisolated struct IPodSyncExpectation: Equatable, Sendable {
    let presentDatabaseIDs: Set<UInt64>
    let absentDatabaseIDs: Set<UInt64>
    let playlistIDs: Set<UInt64>

    init(outcome: IPodSyncOutcome, removals: Set<UInt64>, playlists: [IPodPlaylistRequest]?) {
        presentDatabaseIDs = Set(outcome.addedDatabaseIDs.values)
        absentDatabaseIDs = outcome.removed > 0 ? removals : []
        playlistIDs = Set((playlists ?? []).map(\.id))
    }

    var isEmpty: Bool { presentDatabaseIDs.isEmpty && absentDatabaseIDs.isEmpty && playlistIDs.isEmpty }

    func isMet(by database: ITunesDatabase) -> Bool {
        let trackIDs = Set(database.tracks.map(\.databaseID))
        let playlists = Set(database.userPlaylists.map(\.id))
        return presentDatabaseIDs.isSubset(of: trackIDs) && absentDatabaseIDs.isDisjoint(with: trackIDs)
            && playlistIDs.isSubset(of: playlists)
    }
}
