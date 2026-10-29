import Foundation

/// What a finished `DeviceSyncJob` reports.
nonisolated struct DeviceSyncCompletion: Sendable {
    let summary: SyncSummary
    /// Checked once the sync is over; `true` means another app has since undone it.
    var wasOverwritten: (@Sendable () async -> Bool)?
}
