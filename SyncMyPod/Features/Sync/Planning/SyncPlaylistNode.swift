import Foundation

nonisolated struct SyncPlaylistNode: Identifiable, Equatable, Sendable {
    let key: String
    let name: String
    let trackCount: Int

    var id: String { key }
}
