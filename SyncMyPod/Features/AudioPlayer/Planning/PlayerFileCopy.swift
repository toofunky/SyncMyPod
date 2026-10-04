import Foundation

/// A library file to copy onto the player.
nonisolated struct PlayerFileCopy: Equatable, Sendable {
    let request: IPodSyncRequest
    /// Relative to the volume.
    let destination: String
    /// An earlier copy at another path, deleted once the new one is in place.
    var replacing: String?

    var byteCount: Int64 { Int64(request.draft.fileSize) }
}
