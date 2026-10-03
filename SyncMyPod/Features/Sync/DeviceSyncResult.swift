import Foundation

nonisolated enum DeviceSyncResult: Equatable, Sendable {
    case finished(SyncSummary)
    case failed(String, deviceKind: String)
    /// Another app replaced the iPod's database after the sync finished.
    case overwritten

    var title: String {
        switch self {
        case .finished(let summary) where summary.wasCancelled: "Sync Cancelled"
        case .finished: "Sync Complete"
        case .failed(_, let deviceKind): "Couldn't Sync \(deviceKind)"
        case .overwritten: "iPod Changes Were Undone"
        }
    }

    var message: String {
        switch self {
        case .finished(let summary): Self.message(for: summary)
        case .failed(let message, _): message
        case .overwritten:
            "Finder or Music replaced the iPod's database right after the sync. To stop this, turn on "
                + "“Prevent iPods, iPhones, and iPads from syncing automatically” in Music › Settings › Devices, "
                + "then sync again."
        }
    }

    private static func message(for summary: SyncSummary) -> String {
        var parts = ["Added \(songs(summary.added))."]
        if summary.updated > 0 { parts.append("Updated \(songs(summary.updated)).") }
        if summary.removed > 0 { parts.append("Removed \(songs(summary.removed)).") }
        if summary.syncedPlaylistCount > 0 {
            parts.append("Synced \(count(summary.syncedPlaylistCount, "playlist")).")
        }
        if summary.skipped > 0 { parts.append("\(summary.skipped) already on the \(summary.deviceKind).") }
        if summary.changedCount > 0 { parts.append("Eject the \(summary.deviceKind) before unplugging it.") }
        return parts.joined(separator: " ")
    }

    private static func songs(_ count: Int) -> String {
        Self.count(count, "song")
    }

    private static func count(_ count: Int, _ noun: String) -> String {
        "\(count) \(noun)\(count == 1 ? "" : "s")"
    }
}
