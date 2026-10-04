import Foundation

/// Everything a player's plan depends on, so it's recalculated, away from the main actor, only when one changes.
nonisolated struct PlayerPlanInput: Equatable, Sendable {
    let library: SyncLibrarySnapshot
    let selection: SyncSelection
    let contents: PlayerDeviceContents
    let config: AudioPlayerConfig
    let missingSources: Set<String>
    let sidecars: LibrarySidecars

    @concurrent
    func plan() async -> PlayerSyncPlan {
        let playlists = selection.playlists(in: library.playlists)
        let tracks = selection.partition(library.tracks, syncedPlaylists: playlists)
        return contents.planner(for: config, missingSources: missingSources, sidecars: sidecars)
            .plan(selected: tracks.selected.map(\.request), unselected: tracks.unselected.map(\.request),
                  playlists: playlists)
    }
}
