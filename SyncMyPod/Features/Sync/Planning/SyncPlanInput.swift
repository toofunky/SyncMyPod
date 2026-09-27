import Foundation

/// Everything a plan depends on, so it's recalculated, away from the main actor, only when one changes.
nonisolated struct SyncPlanInput: Equatable, Sendable {
    let library: SyncLibrarySnapshot
    let mode: SyncMode
    let selectedAlbums: Set<String>
    let selectedGenres: Set<String>
    let selectedPlaylists: Set<String>
    let onDevice: ITunesDatabase
    let manifest: LoadedSyncManifest

    @concurrent
    func plan() async -> SyncPlan {
        let playlists = library.playlists
            .filter { mode == .allSongs || selectedPlaylists.contains($0.key) }
            .map(\.request)
        return SyncPlan.make(snapshots: library.tracks, mode: mode, selectedAlbums: selectedAlbums,
                             selectedGenres: selectedGenres, playlists: playlists, onDevice: onDevice.tracks,
                             devicePlaylists: onDevice.playlists, manifest: manifest.manifest,
                             strayDatabaseIDs: manifest.strayDatabaseIDs)
    }
}
