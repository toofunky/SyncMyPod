import Foundation

/// The iPod track a library file was copied to, and the file as it was then.
nonisolated struct SyncManifestEntry: Codable, Equatable, Sendable {
    let databaseID: UInt64
    /// `nil` when the track was matched after the file changed, so the next sync rewrites it.
    let source: SyncSource?
}
