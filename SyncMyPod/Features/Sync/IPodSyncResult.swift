import Foundation

nonisolated enum IPodSyncResult: Equatable, Sendable {
    case finished(IPodSyncOutcome)
    case failed(String)

    var title: String {
        switch self {
        case .finished(let outcome) where outcome.wasCancelled: "Sync Cancelled"
        case .finished: "Sync Complete"
        case .failed: "Couldn't Sync iPod"
        }
    }

    var message: String {
        switch self {
        case .finished(let outcome): Self.summary(of: outcome)
        case .failed(let message): message
        }
    }

    private static func summary(of outcome: IPodSyncOutcome) -> String {
        var parts = ["Added \(songs(outcome.addedCount))."]
        if outcome.updatedCount > 0 { parts.append("Updated \(songs(outcome.updatedCount)).") }
        if outcome.removed > 0 { parts.append("Removed \(songs(outcome.removed)).") }
        if outcome.skipped > 0 { parts.append("\(outcome.skipped) already on the iPod.") }
        let changed = outcome.addedCount + outcome.updatedCount + outcome.removed
        if changed > 0 { parts.append("Eject the iPod before unplugging it.") }
        return parts.joined(separator: " ")
    }

    private static func songs(_ count: Int) -> String {
        "\(count) \(count == 1 ? "song" : "songs")"
    }
}
