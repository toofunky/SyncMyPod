import Foundation

extension DeviceSyncModel {
    /// Non-`nil` `playlists` replace every playlist earlier syncs wrote.
    func sync(_ requests: [SyncRequest], removing removals: Set<UInt64> = [],
              playlists: [SyncPlaylistRequest]? = nil, to iPod: IPodDevice) {
        guard !isSyncing, !requests.isEmpty || !removals.isEmpty || playlists != nil else { return }
        do {
            run(IPodSyncJob(syncer: try IPodTrackSyncer(device: iPod), deviceID: iPod.id, requests: requests,
                            removals: removals, playlists: playlists))
        } catch {
            recordFailure(error, deviceKind: "iPod")
        }
    }
}
