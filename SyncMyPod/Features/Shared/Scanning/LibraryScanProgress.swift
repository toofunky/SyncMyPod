import Foundation

nonisolated struct LibraryScanProgress: Equatable, Sendable {
    let completed: Int
    let total: Int
}
