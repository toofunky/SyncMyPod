import Foundation
import Observation

@Observable
@MainActor
final class IPodSyncModel {
    private(set) var progress: IPodSyncProgress?
    private(set) var completedSyncCount = 0
    private(set) var isCancelling = false
    var result: IPodSyncResult?

    @ObservationIgnored private var syncTask: Task<Void, Never>?

    var isSyncing: Bool { syncTask != nil }

    /// Non-`nil` `playlists` replace every playlist earlier syncs wrote.
    func sync(_ requests: [IPodSyncRequest], removing removals: Set<UInt64> = [],
              playlists: [IPodPlaylistRequest]? = nil, to device: IPodDevice) {
        guard !isSyncing, !requests.isEmpty || !removals.isEmpty || playlists != nil else { return }
        let syncer: IPodTrackSyncer
        do {
            syncer = try IPodTrackSyncer(device: device)
        } catch {
            result = .failed(error.localizedDescription)
            return
        }
        progress = IPodSyncProgress(completed: 0, total: requests.count, currentTitle: nil)
        syncTask = Task { await run(requests, removing: removals, playlists: playlists, with: syncer) }
    }

    func cancel() {
        isCancelling = true
        syncTask?.cancel()
    }

    private func run(_ requests: [IPodSyncRequest], removing removals: Set<UInt64>,
                     playlists: [IPodPlaylistRequest]?, with syncer: IPodTrackSyncer) async {
        do {
            let outcome = try await syncer.sync(adding: requests, removing: removals,
                                                playlists: playlists) { [weak self] update in
                await self?.report(update)
            }
            result = .finished(outcome)
        } catch {
            result = .failed(error.localizedDescription)
        }
        progress = nil
        isCancelling = false
        syncTask = nil
        completedSyncCount += 1
    }

    private func report(_ update: IPodSyncProgress) {
        progress = update
    }
}
