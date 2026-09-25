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

    func sync(_ requests: [IPodSyncRequest], to device: IPodDevice) {
        guard !isSyncing, !requests.isEmpty else { return }
        guard device.requiresDatabaseHash == false else {
            let name = device.generationDescription ?? "this iPod"
            result = .failed(IPodSyncError.unsupportedDevice(name).localizedDescription)
            return
        }
        progress = IPodSyncProgress(completed: 0, total: requests.count, currentTitle: nil)
        syncTask = Task { await run(requests, on: device.volumeURL) }
    }

    func cancel() {
        isCancelling = true
        syncTask?.cancel()
    }

    private func run(_ requests: [IPodSyncRequest], on volumeURL: URL) async {
        do {
            let outcome = try await IPodTrackSyncer(volumeURL: volumeURL).add(requests) { [weak self] update in
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
