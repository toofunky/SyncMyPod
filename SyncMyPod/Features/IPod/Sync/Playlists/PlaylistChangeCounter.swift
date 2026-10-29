import Foundation

/// Counts the playlists a sync would write or remove because the iPod's copy differs from the library's.
nonisolated enum PlaylistChangeCounter {
    static func count(_ playlists: [IPodPlaylistRequest], resolver: PlaylistTrackResolver, onDevice: [ITunesTrack],
                      devicePlaylists: [ITunesPlaylist]) -> Int {
        let databaseIDs = Dictionary(onDevice.map { ($0.id, $0.databaseID) }, uniquingKeysWith: { first, _ in first })
        let existing = Dictionary(devicePlaylists.filter { !$0.isMaster }.map { ($0.id, $0) },
                                  uniquingKeysWith: { first, _ in first })
        let changed = playlists.filter { playlist in
            guard let copy = existing[playlist.id] else { return true }
            return copy.name != playlist.name
                || copy.trackIDs.compactMap { databaseIDs[$0] } != resolver.draft(for: playlist).databaseIDs
        }
        let wanted = Set(playlists.map(\.id))
        let removed = resolver.manifest.playlistIDs.filter { !wanted.contains($0) && existing[$0] != nil }
        return changed.count + removed.count
    }
}
