import Foundation

nonisolated extension SyncRequest {
    var matchKey: IPodTrackMatchKey { IPodTrackMatchKey(draft) }
}
