import Foundation

nonisolated extension SyncPlan {
    var totals: SyncPlanTotals {
        SyncPlanTotals(addCount: requests.count, addBytes: byteCount, updateCount: updates.count,
                       updateBytes: updatedByteCount, removeCount: removals.count, removeBytes: removedByteCount,
                       playlistChangeCount: playlistChangeCount, selectedCount: selectedCount)
    }
}
