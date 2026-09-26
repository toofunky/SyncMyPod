import Foundation

/// A library playlist to put on the iPod, with its songs in play order.
nonisolated struct IPodPlaylistRequest: Identifiable, Equatable, Sendable {
    let id: UInt64
    let name: String
    let createdAt: Date
    let tracks: [IPodSyncRequest]
}
