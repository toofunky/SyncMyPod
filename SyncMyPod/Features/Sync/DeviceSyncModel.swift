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
    private(set) var syncingDeviceKind = DeviceKind.iPod
    var result: DeviceSyncResult?

    @ObservationIgnored private var syncTask: Task<Void, Never>?
    @ObservationIgnored private var verificationTask: Task<Void, Never>?

    /// Shows progress, runs the job and records its result.
    func run(_ job: some DeviceSyncJob) {
        guard !isSyncing else { return }
        verificationTask?.cancel()
        progress = SyncProgress(completed: 0, total: job.total, currentTitle: nil)
        isSyncing = true
        syncingDeviceID = job.deviceID
        syncingDeviceKind = job.deviceKind
        syncTask = Task {
            do {
                let completion = try await job.run { update in await self.report(update) }
                result = .finished(completion.summary)
                if let wasOverwritten = completion.wasOverwritten { verify(wasOverwritten) }
            } catch {
                result = .failed(error.localizedDescription, deviceKind: job.deviceKind)
            }
            finish()
        }
    }

    /// For a sync that couldn't be set up, so never started.
    func recordFailure(_ error: any Error, deviceKind: DeviceKind) {
        result = .failed(error.localizedDescription, deviceKind: deviceKind)
    }

    func cancel() {
        isCancelling = true
        syncTask?.cancel()
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
    private func verify(_ wasOverwritten: @escaping @Sendable () async -> Bool) {
        verificationTask = Task {
            let overwritten = await wasOverwritten()
            guard overwritten, !Task.isCancelled, !isSyncing else { return }
            result = .overwritten
            completedSyncCount += 1
        }
    }

    private func report(_ update: SyncProgress) {
        progress = update
    }
}
