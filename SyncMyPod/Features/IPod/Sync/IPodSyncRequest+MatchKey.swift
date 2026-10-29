import Foundation

nonisolated extension IPodSyncRequest {
    var matchKey: IPodTrackMatchKey { IPodTrackMatchKey(draft) }
}
