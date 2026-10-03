import Foundation

/// Where a library file was copied on the player, and the file as it was then.
nonisolated struct PlayerManifestEntry: Codable, Equatable, Sendable {
    /// Relative to the volume.
    let path: String
    let source: SyncSource?
}
