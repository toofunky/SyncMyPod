import Foundation

/// Finds the iPod track each playlist song was copied to: through the manifest first, then by tags.
nonisolated struct PlaylistTrackResolver: Sendable {
    let manifest: SyncManifest
    private let databaseIDsByKey: [IPodTrackMatchKey: UInt64]

    init(manifest: SyncManifest, onDevice: [ITunesTrack]) {
        self.manifest = manifest
        databaseIDsByKey = Dictionary(onDevice.map { (IPodTrackMatchKey($0), $0.databaseID) },
                                      uniquingKeysWith: { first, _ in first })
    }

    /// `synced` holds the database IDs of tracks copied since the manifest was read, keyed by source path.
    func draft(for playlist: IPodPlaylistRequest, synced: [String: UInt64] = [:]) -> ITunesPlaylistDraft {
        let resolved = playlist.tracks.compactMap { track in
            databaseID(for: track, synced: synced).map { ($0, track.draft.album) }
        }
        return ITunesPlaylistDraft(id: playlist.id, name: playlist.name, createdAt: playlist.createdAt,
                                   databaseIDs: resolved.map(\.0),
                                   podcastShows: playlist.isPodcasts ? resolved.map(\.1) : nil)
    }

    private func databaseID(for request: IPodSyncRequest, synced: [String: UInt64]) -> UInt64? {
        synced[request.sourcePath] ?? manifest.entry(for: request)?.databaseID ?? databaseIDsByKey[request.matchKey]
    }
}
