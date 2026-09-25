import Foundation

nonisolated struct SyncAlbumNode: Identifiable, Equatable, Sendable {
    let key: String
    let title: String
    let trackCount: Int
    let byteCount: Int64

    var id: String { key }
}
