import Foundation

nonisolated struct SyncGenreNode: Identifiable, Equatable, Sendable {
    let name: String
    let trackCount: Int
    let byteCount: Int64

    var id: String { name }
}
