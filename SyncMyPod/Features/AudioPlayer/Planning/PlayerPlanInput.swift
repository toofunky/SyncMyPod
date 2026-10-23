import Foundation

/// Everything a player's plan depends on, so it's recalculated, away from the main actor, only when one changes.
nonisolated struct PlayerPlanInput: Equatable, Sendable {
    let library: SyncLibrarySnapshot
    let selection: SyncSelection
    let contents: PlayerDeviceContents
    let config: AudioPlayerConfig
    let missingSources: Set<String>
    let sidecars: LibrarySidecars

    /// Podcast episodes and audiobook files go in alongside songs, with a playlist for each chosen podcast and
    /// book when the config asks.
    @concurrent
    func plan() async -> PlayerSyncPlan {
        let playlists = selection.playlists(in: library.playlists)
        let tracks = selection.partition(library.tracks, syncedPlaylists: playlists)
        let podcasts = selection.partition(library.podcasts)
        let books = selection.partition(library.audiobooks)
        let podcastPlaylists = config.makesPodcastPlaylists ? podcasts.selected.map(\.playlist) : []
        let bookPlaylists = config.makesAudiobookPlaylists ? books.selected.map(\.playlist) : []
        return contents.planner(for: config, missingSources: missingSources, sidecars: sidecars)
            .plan(selected: tracks.selected.map(\.request) + podcasts.selected.flatMap(\.episodes)
                      + books.selected.flatMap(\.files),
                  unselected: tracks.unselected.map(\.request) + podcasts.unselected.flatMap(\.episodes)
                      + books.unselected.flatMap(\.files),
                  playlists: playlists + podcastPlaylists + bookPlaylists)
    }
}
