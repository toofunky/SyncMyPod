import Foundation

extension LibraryPlaylist {
    /// Stable across syncs, so the iPod's copy is replaced rather than duplicated.
    var iPodPlaylistID: UInt64 {
        withUnsafeBytes(of: playlistID.uuid) { $0.loadUnaligned(as: UInt64.self) }
    }

    var syncKey: String { playlistID.uuidString }

    /// Songs whose file is no longer in the library are left out.
    func syncSnapshot(requestsByPath: [String: IPodSyncRequest]) -> SyncPlaylistSnapshot {
        let request = IPodPlaylistRequest(id: iPodPlaylistID, name: name, createdAt: createdAt,
                                          tracks: trackPaths.compactMap { requestsByPath[$0] })
        return SyncPlaylistSnapshot(key: syncKey, request: request)
    }
}
