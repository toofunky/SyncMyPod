import Foundation

nonisolated struct LibraryScanSummary: Equatable, Sendable {
    var added = 0
    var updated = 0
    var unchanged = 0
    var removed = 0
    var skipped = 0

    var displayText: String {
        "\(added) added · \(updated) updated · \(removed) removed · \(skipped) skipped"
    }

    mutating func record(_ outcome: LibraryScanOutcome) {
        switch outcome {
        case .added: added += 1
        case .updated: updated += 1
        case .unchanged: unchanged += 1
        case .removed: removed += 1
        case .skipped: skipped += 1
        }
    }
}
