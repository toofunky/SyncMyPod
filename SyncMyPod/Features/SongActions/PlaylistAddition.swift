import Foundation

/// Songs about to be added to a playlist, some of which may already be in it.
struct PlaylistAddition {
    let tracks: [LibraryTrack]
    let playlist: LibraryPlaylist

    var duplicates: [LibraryTrack] {
        let existing = Set(playlist.trackPaths)
        return tracks.filter { existing.contains($0.filePath) }
    }

    var newTracks: [LibraryTrack] {
        let existing = Set(playlist.trackPaths)
        return tracks.filter { !existing.contains($0.filePath) }
    }

    func addAll() {
        playlist.append(tracks)
    }

    func addNewTracks() {
        playlist.append(newTracks)
    }
}
