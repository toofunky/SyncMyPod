@testable import SyncMyPod

actor ProgressRecorder {
    private(set) var updates: [IPodSyncProgress] = []

    func record(_ update: IPodSyncProgress) {
        updates.append(update)
    }
}
