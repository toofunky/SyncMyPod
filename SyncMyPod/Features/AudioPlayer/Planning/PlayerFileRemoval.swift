import Foundation

/// A copy on the player whose library file is no longer selected or was deleted.
nonisolated struct PlayerFileRemoval: Equatable, Sendable {
    /// The library file's path, which keys the manifest.
    let sourcePath: String
    /// Relative to the volume.
    let path: String
    let byteCount: Int64

    var fileName: String { (path as NSString).lastPathComponent }
}
