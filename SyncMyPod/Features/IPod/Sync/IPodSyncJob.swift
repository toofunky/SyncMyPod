import Foundation

/// Adds, updates and removes tracks and playlists on an iPod, then watches for Finder or Music undoing it.
nonisolated struct IPodSyncJob: DeviceSyncJob {
    let syncer: IPodTrackSyncer
    let deviceID: String
    let requests: [SyncRequest]
    let removals: Set<UInt64>
    /// Non-`nil` playlists replace every playlist earlier syncs wrote.
    let playlists: [SyncPlaylistRequest]?

    var deviceKind: DeviceKind { .iPod }
    var total: Int { requests.count }

    func run(progress: @escaping @Sendable (SyncProgress) async -> Void) async throws -> DeviceSyncCompletion {
        let outcome = try await syncer.sync(adding: requests, removing: removals, playlists: playlists,
                                            progress: progress)
        let expectation = IPodSyncExpectation(outcome: outcome, removals: removals, playlists: playlists)
        let volumeURL = syncer.volumeURL
        let check: @Sendable () async -> Bool = {
            await IPodSyncVerifier.wasOverwritten(expectation, onVolume: volumeURL)
        }
        return DeviceSyncCompletion(summary: SyncSummary(outcome, deviceKind: deviceKind),
                                    wasOverwritten: expectation.isEmpty ? nil : check)
    }
}
