@testable import SyncMyPod

actor ProgressRecorder {
    private(set) var updates: [SyncProgress] = []

    func record(_ update: SyncProgress) {
        updates.append(update)
    }
}
