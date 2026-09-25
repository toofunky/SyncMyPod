import Foundation

extension LibraryPlaylist {
    /// Stable across syncs, so the iPod's copy is replaced rather than duplicated.
    var iPodPlaylistID: UInt64 {
        withUnsafeBytes(of: playlistID.uuid) { $0.loadUnaligned(as: UInt64.self) }
    }

    var syncKey: String { playlistID.uuidString }

    /// Songs whose file is no longer in the library are left out.
    func syncRequest(tracksByPath: [String: LibraryTrack]) -> IPodPlaylistRequest {
        IPodPlaylistRequest(id: iPodPlaylistID, name: name, createdAt: createdAt,
                            tracks: trackPaths.compactMap { tracksByPath[$0]?.syncRequest })
    }

    /// Every playlist in All Songs mode, otherwise only the selected ones.
    static func syncRequests(_ playlists: [LibraryPlaylist], tracks: [LibraryTrack],
                             settings: IPodSyncSettings) -> [IPodPlaylistRequest] {
        let tracksByPath = Dictionary(tracks.map { ($0.filePath, $0) }, uniquingKeysWith: { first, _ in first })
        return playlists
            .filter { settings.mode == .allSongs || settings.selectedPlaylists.contains($0.syncKey) }
            .map { $0.syncRequest(tracksByPath: tracksByPath) }
    }
}
