import Foundation

nonisolated struct IPodSyncRequest: Equatable, Sendable {
    let sourceURL: URL
    let draft: ITunesTrackDraft

    var matchKey: IPodTrackMatchKey { IPodTrackMatchKey(draft) }
}
