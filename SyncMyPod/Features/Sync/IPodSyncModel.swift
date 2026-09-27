import Foundation
import Observation

@Observable
@MainActor
final class IPodSyncModel {
    private(set) var progress: IPodSyncProgress?
    private(set) var completedSyncCount = 0
    private(set) var isCancelling = false
    private(set) var isSyncing = false
    var result: IPodSyncResult?

    @ObservationIgnored private var syncTask: Task<Void, Never>?
    @ObservationIgnored private var verificationTask: Task<Void, Never>?

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
        verificationTask?.cancel()
        progress = IPodSyncProgress(completed: 0, total: requests.count, currentTitle: nil)
        isSyncing = true
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
            verify(IPodSyncExpectation(outcome: outcome, removals: removals, playlists: playlists),
                   onVolume: syncer.volumeURL)
        } catch {
            result = .failed(error.localizedDescription)
        }
        progress = nil
        isCancelling = false
        syncTask = nil
        isSyncing = false
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

    private func report(_ update: IPodSyncProgress) {
        progress = update
    }
}
