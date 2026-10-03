import Foundation
import Observation

/// Runs one sync at a time, to whichever connected device asked for it.
@Observable
@MainActor
final class DeviceSyncModel {
    private(set) var progress: SyncProgress?
    private(set) var completedSyncCount = 0
    private(set) var isCancelling = false
    private(set) var isSyncing = false
    private(set) var syncingDeviceID: String?
    private(set) var syncingDeviceKind = "iPod"
    var result: DeviceSyncResult?

    @ObservationIgnored private var syncTask: Task<Void, Never>?
    @ObservationIgnored private var verificationTask: Task<Void, Never>?

    /// Non-`nil` `playlists` replace every playlist earlier syncs wrote.
    func sync(_ requests: [IPodSyncRequest], removing removals: Set<UInt64> = [],
              playlists: [IPodPlaylistRequest]? = nil, to device: ConnectedDevice) {
        guard !isSyncing, !requests.isEmpty || !removals.isEmpty || playlists != nil else { return }
        switch device {
        case .iPod(let iPod):
            syncIPod(iPod, adding: requests, removing: removals, playlists: playlists, as: device)
        case .audioPlayer(let player):
            addToPlayer(requests, player: player, as: device)
        }
    }

    /// Carries out a plan made on the player's Sync tab.
    func sync(_ plan: PlayerSyncPlan, to player: AudioPlayerDevice) {
        guard !isSyncing, !plan.isEmpty else { return }
        let syncer = PlayerTrackSyncer(device: player)
        start(on: .audioPlayer(player), total: plan.writes.count) { report in
            try await syncer.sync(plan, progress: report)
        }
    }

    /// Copies songs chosen in the library, with their covers and lyrics, without removing anything or
    /// touching playlists.
    private func addToPlayer(_ requests: [IPodSyncRequest], player: AudioPlayerDevice, as device: ConnectedDevice) {
        let syncer = PlayerTrackSyncer(device: player)
        let config = player.config
        start(on: device, total: requests.count) { report in
            let contents = await PlayerDeviceContents.load(from: player)
            let sidecars = await LibrarySidecarFinder.find(besideSongsAt: requests.map(\.sourcePath),
                                                           covers: config.copyCovers, lyrics: config.copyLyricFiles)
            let plan = contents.planner(for: config, sidecars: sidecars).plan(selected: requests, playlists: nil)
            return try await syncer.sync(plan, progress: report)
        }
    }

    func cancel() {
        isCancelling = true
        syncTask?.cancel()
    }

    private func syncIPod(_ iPod: IPodDevice, adding requests: [IPodSyncRequest], removing removals: Set<UInt64>,
                          playlists: [IPodPlaylistRequest]?, as device: ConnectedDevice) {
        let syncer: IPodTrackSyncer
        do {
            syncer = try IPodTrackSyncer(device: iPod)
        } catch {
            result = .failed(error.localizedDescription, deviceKind: device.kindName)
            return
        }
        verificationTask?.cancel()
        start(on: device, total: requests.count) { [weak self] report in
            let outcome = try await syncer.sync(adding: requests, removing: removals, playlists: playlists,
                                                progress: report)
            self?.verify(IPodSyncExpectation(outcome: outcome, removals: removals, playlists: playlists),
                         onVolume: syncer.volumeURL)
            return SyncSummary(outcome, deviceKind: device.kindName)
        }
    }

    /// Shows progress, runs `work` off the main actor and records its result.
    private func start(on device: ConnectedDevice, total: Int,
                       _ work: @escaping (@escaping @Sendable (SyncProgress) async -> Void) async throws -> SyncSummary) {
        progress = SyncProgress(completed: 0, total: total, currentTitle: nil)
        isSyncing = true
        syncingDeviceID = device.id
        syncingDeviceKind = device.kindName
        syncTask = Task {
            do {
                result = .finished(try await work { update in await self.report(update) })
            } catch {
                result = .failed(error.localizedDescription, deviceKind: device.kindName)
            }
            finish()
        }
    }

    private func finish() {
        progress = nil
        isCancelling = false
        syncTask = nil
        isSyncing = false
        syncingDeviceID = nil
        completedSyncCount += 1
    }

    /// Reloads the Sync tab and says so if another app undid the sync.
    private func verify(_ expectation: IPodSyncExpectation, onVolume volumeURL: URL) {
        guard !expectation.isEmpty else { return }
        verificationTask = Task {
            let overwritten = await IPodSyncVerifier.wasOverwritten(expectation, onVolume: volumeURL)
            guard overwritten, !Task.isCancelled, !isSyncing else { return }
            result = .overwritten
            completedSyncCount += 1
        }
    }

    private func report(_ update: SyncProgress) {
        progress = update
    }
}
