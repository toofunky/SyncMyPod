import Foundation

nonisolated struct IPodSyncProgress: Equatable, Sendable {
    let completed: Int
    let total: Int
    /// The track being copied, or `nil` once the databases are being written.
    let currentTitle: String?

    var fractionCompleted: Double { total == 0 ? 1 : Double(completed) / Double(total) }
}
