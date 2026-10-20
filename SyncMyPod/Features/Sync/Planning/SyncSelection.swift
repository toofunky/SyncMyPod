import Foundation

/// Which library songs and playlists a device should hold, whatever kind of device it is.
nonisolated struct SyncSelection: Equatable, Sendable {
    var mode: SyncMode
    var albums: Set<String> = []
    var genres: Set<String> = []
    var playlists: Set<String> = []
    var podcasts: Set<String> = []
    var audiobooks: Set<String> = []

    func playlists(in library: [SyncPlaylistSnapshot]) -> [IPodPlaylistRequest] {
        library.filter { mode == .allSongs || playlists.contains($0.key) }.map(\.request)
    }

    /// Every downloaded episode of each chosen podcast, or of every podcast when syncing everything.
    func partition(_ library: [SyncPodcastSnapshot])
        -> (selected: [SyncPodcastSnapshot], unselected: [SyncPodcastSnapshot]) {
        let isSelected = { (podcast: SyncPodcastSnapshot) in mode == .allSongs || podcasts.contains(podcast.key) }
        return (library.filter(isSelected), library.filter { !isSelected($0) })
    }

    /// Every file of each chosen book, or of every book when syncing everything.
    func partition(_ library: [SyncAudiobookSnapshot])
        -> (selected: [SyncAudiobookSnapshot], unselected: [SyncAudiobookSnapshot]) {
        let isSelected = { (book: SyncAudiobookSnapshot) in mode == .allSongs || audiobooks.contains(book.key) }
        return (library.filter(isSelected), library.filter { !isSelected($0) })
    }

    /// Songs in `syncedPlaylists` are selected whatever the mode, album and genre selection.
    func partition(_ tracks: [SyncTrackSnapshot], syncedPlaylists: [IPodPlaylistRequest])
        -> (selected: [SyncTrackSnapshot], unselected: [SyncTrackSnapshot]) {
        let playlistPaths = Set(syncedPlaylists.flatMap { $0.tracks.map(\.sourcePath) })
        let isSelected = { (track: SyncTrackSnapshot) in
            mode == .allSongs || albums.contains(track.albumKey) || genres.contains(track.genre)
                || playlistPaths.contains(track.filePath)
        }
        return (tracks.filter(isSelected), tracks.filter { !isSelected($0) })
    }
}
