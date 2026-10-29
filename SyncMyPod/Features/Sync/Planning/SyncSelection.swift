import Foundation

/// Which library songs and playlists a device should hold, whatever kind of device it is.
nonisolated struct SyncSelection: Equatable, Sendable {
    var songs = SyncScope.all
    var playlistScope = SyncScope.all
    var podcastScope = SyncScope.all
    var audiobookScope = SyncScope.all
    var albums: Set<String> = []
    var genres: Set<String> = []
    var playlists: Set<String> = []
    var podcasts: Set<String> = []
    var audiobooks: Set<String> = []

    func playlists(in library: [SyncPlaylistSnapshot]) -> [SyncPlaylistRequest] {
        library.filter { playlistScope.includes($0.key, in: playlists) }.map(\.request)
    }

    /// Every downloaded episode of each chosen podcast.
    func partition(_ library: [SyncPodcastSnapshot])
        -> (selected: [SyncPodcastSnapshot], unselected: [SyncPodcastSnapshot]) {
        let isSelected = { (podcast: SyncPodcastSnapshot) in podcastScope.includes(podcast.key, in: podcasts) }
        return (library.filter(isSelected), library.filter { !isSelected($0) })
    }

    /// Every file of each chosen book.
    func partition(_ library: [SyncAudiobookSnapshot])
        -> (selected: [SyncAudiobookSnapshot], unselected: [SyncAudiobookSnapshot]) {
        let isSelected = { (book: SyncAudiobookSnapshot) in audiobookScope.includes(book.key, in: audiobooks) }
        return (library.filter(isSelected), library.filter { !isSelected($0) })
    }

    /// Songs in `syncedPlaylists` are selected whatever the song scope, album and genre selection.
    func partition(_ tracks: [SyncTrackSnapshot], syncedPlaylists: [SyncPlaylistRequest])
        -> (selected: [SyncTrackSnapshot], unselected: [SyncTrackSnapshot]) {
        let playlistPaths = Set(syncedPlaylists.flatMap { $0.tracks.map(\.sourcePath) })
        let isSelected = { (track: SyncTrackSnapshot) in
            songs.includes(track.albumKey, in: albums) || songs.includes(track.genre, in: genres)
                || playlistPaths.contains(track.filePath)
        }
        return (tracks.filter(isSelected), tracks.filter { !isSelected($0) })
    }
}
