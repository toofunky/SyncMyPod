import Foundation

/// Carries out a plan made on the player's Sync tab, or plans and copies songs added from the library.
nonisolated struct PlayerSyncJob: DeviceSyncJob {
    let device: AudioPlayerDevice
    let total: Int
    private let plan: @Sendable () async -> PlayerSyncPlan

    init(device: AudioPlayerDevice, plan: PlayerSyncPlan) {
        self.device = device
        total = plan.writes.count
        self.plan = { plan }
    }

    /// Copies the songs, with their covers and lyrics, without removing anything or touching playlists.
    init(device: AudioPlayerDevice, adding requests: [SyncRequest]) {
        self.device = device
        total = requests.count
        let config = device.config
        plan = {
            let contents = await PlayerDeviceContents.load(from: device)
            let sidecars = await LibrarySidecarFinder.find(besideSongsAt: requests.map(\.sourcePath),
                                                           covers: config.copyCovers, lyrics: config.copyLyricFiles)
            return contents.planner(for: config, sidecars: sidecars).plan(selected: requests, playlists: nil)
        }
    }

    var deviceID: String { device.id }
    var deviceKind: String { "player" }

    func run(progress: @escaping @Sendable (SyncProgress) async -> Void) async throws -> DeviceSyncCompletion {
        let summary = try await PlayerTrackSyncer(device: device).sync(await plan(), progress: progress)
        return DeviceSyncCompletion(summary: summary)
    }
}
