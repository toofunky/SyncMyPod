import Foundation

/// Everything a plan depends on, so it's recalculated, away from the main actor, only when one changes.
nonisolated struct SyncPlanInput: Equatable, Sendable {
    let library: SyncLibrarySnapshot
    let selection: SyncSelection
    let onDevice: ITunesDatabase
    let manifest: LoadedSyncManifest
    var makesAudiobookPlaylists = false

    /// Chosen podcasts' episodes go on the iPod, listed together in its Podcasts list. Chosen books' files go on
    /// it too, and the iPod lists them under Audiobooks by itself, with a playlist for each book when asked.
    @concurrent
    func plan() async -> SyncPlan {
        let podcasts = selection.partition(library.podcasts)
        let books = selection.partition(library.audiobooks)
        let podcastsList = IPodPlaylistRequest.podcasts(podcasts.selected).map { [$0] } ?? []
        let bookPlaylists = makesAudiobookPlaylists ? books.selected.map(\.playlist) : []
        return SyncPlan.make(snapshots: library.tracks, mode: selection.mode, selectedAlbums: selection.albums,
                             selectedGenres: selection.genres,
                             playlists: selection.playlists(in: library.playlists) + podcastsList + bookPlaylists,
                             onDevice: onDevice.tracks, devicePlaylists: onDevice.playlists,
                             manifest: manifest.manifest, strayDatabaseIDs: manifest.strayDatabaseIDs,
                             episodes: (podcasts.selected.flatMap(\.episodes) + books.selected.flatMap(\.files),
                                        podcasts.unselected.flatMap(\.episodes) + books.unselected.flatMap(\.files)))
    }
}
