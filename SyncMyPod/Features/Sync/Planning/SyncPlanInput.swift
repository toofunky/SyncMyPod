import Foundation

/// Everything a plan depends on, so it's recalculated, away from the main actor, only when one changes.
nonisolated struct SyncPlanInput: Equatable, Sendable {
    let library: SyncLibrarySnapshot
    let selection: SyncSelection
    let onDevice: ITunesDatabase
    let manifest: LoadedSyncManifest

    /// Chosen podcasts' episodes go on the iPod, listed together in its Podcasts list.
    @concurrent
    func plan() async -> SyncPlan {
        let podcasts = selection.partition(library.podcasts)
        let podcastsList = IPodPlaylistRequest.podcasts(podcasts.selected).map { [$0] } ?? []
        return SyncPlan.make(snapshots: library.tracks, mode: selection.mode, selectedAlbums: selection.albums,
                             selectedGenres: selection.genres,
                             playlists: selection.playlists(in: library.playlists) + podcastsList,
                             onDevice: onDevice.tracks, devicePlaylists: onDevice.playlists,
                             manifest: manifest.manifest, strayDatabaseIDs: manifest.strayDatabaseIDs,
                             episodes: (podcasts.selected.flatMap(\.episodes), podcasts.unselected.flatMap(\.episodes)))
    }
}
