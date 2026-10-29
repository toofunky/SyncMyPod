import Foundation

nonisolated struct SyncPlaylistSnapshot: Equatable, Sendable {
    let key: String
    let request: SyncPlaylistRequest
}
