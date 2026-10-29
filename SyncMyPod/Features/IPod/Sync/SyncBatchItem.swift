import Foundation

/// One song a sync copies: new to the iPod, or replacing the copy of a file that changed.
nonisolated enum SyncBatchItem: Equatable, Sendable {
    case add(IPodSyncRequest)
    case update(IPodTrackUpdate)

    var request: IPodSyncRequest {
        switch self {
        case .add(let request): request
        case .update(let update): update.request
        }
    }
}
