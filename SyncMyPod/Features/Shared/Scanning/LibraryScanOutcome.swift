import Foundation

nonisolated enum LibraryScanOutcome: Sendable {
    case added
    case updated
    case unchanged
    case removed
    case skipped
}
