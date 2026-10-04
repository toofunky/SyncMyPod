import Foundation

/// An unchanged copy whose name or folder changed, e.g. after retagging or turning on numbering.
nonisolated struct PlayerFileMove: Equatable, Sendable {
    /// The library file's path, which keys the manifest.
    let sourcePath: String
    /// Both relative to the volume.
    let from: String
    let to: String
}
