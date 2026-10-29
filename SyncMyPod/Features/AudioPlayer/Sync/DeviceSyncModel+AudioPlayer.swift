import Foundation

extension DeviceSyncModel {
    /// Carries out a plan made on the player's Sync tab.
    func sync(_ plan: PlayerSyncPlan, to player: AudioPlayerDevice) {
        guard !plan.isEmpty else { return }
        run(PlayerSyncJob(device: player, plan: plan))
    }

    /// Copies songs chosen in the library without removing anything or touching playlists.
    func add(_ requests: [SyncRequest], to player: AudioPlayerDevice) {
        guard !requests.isEmpty else { return }
        run(PlayerSyncJob(device: player, adding: requests))
    }
}
