import Foundation

/// A library file that changed after it was copied to the iPod.
nonisolated struct IPodTrackUpdate: Equatable, Sendable {
    let request: IPodSyncRequest
    let databaseID: UInt64
    let artworkChanged: Bool
}
