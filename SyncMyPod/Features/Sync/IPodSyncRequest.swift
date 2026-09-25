import Foundation

nonisolated struct IPodSyncRequest: Equatable, Sendable {
    let sourceURL: URL
    let draft: ITunesTrackDraft
    /// The track's database ID from a previous sync, used to skip tracks already on the iPod.
    let existingDatabaseID: UInt64?
}
