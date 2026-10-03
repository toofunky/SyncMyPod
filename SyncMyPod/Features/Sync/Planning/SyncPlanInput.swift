import Foundation

/// Everything a plan depends on, so it's recalculated, away from the main actor, only when one changes.
nonisolated struct SyncPlanInput: Equatable, Sendable {
    let library: SyncLibrarySnapshot
    let selection: SyncSelection
    let onDevice: ITunesDatabase
    let manifest: LoadedSyncManifest

    @concurrent
    func plan() async -> SyncPlan {
        SyncPlan.make(snapshots: library.tracks, mode: selection.mode, selectedAlbums: selection.albums,
                      selectedGenres: selection.genres, playlists: selection.playlists(in: library.playlists),
                      onDevice: onDevice.tracks, devicePlaylists: onDevice.playlists, manifest: manifest.manifest,
                      strayDatabaseIDs: manifest.strayDatabaseIDs)
    }
}
