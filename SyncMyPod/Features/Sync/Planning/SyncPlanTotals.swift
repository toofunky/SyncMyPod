import Foundation

/// The counts and sizes a sync plan shows before it runs, whatever kind of device it's for.
nonisolated struct SyncPlanTotals: Equatable, Sendable {
    var addCount = 0
    var addBytes: Int64 = 0
    var updateCount = 0
    var updateBytes: Int64 = 0
    var moveCount = 0
    var removeCount = 0
    var removeBytes: Int64 = 0
    var playlistChangeCount = 0
    /// Covers and lyric files to copy or remove on a player.
    var sidecarChangeCount = 0
    var sidecarBytes: Int64 = 0
    var selectedCount = 0

    var isEmpty: Bool {
        addCount == 0 && updateCount == 0 && moveCount == 0 && removeCount == 0 && playlistChangeCount == 0
            && sidecarChangeCount == 0
    }

    var alreadyOnDeviceCount: Int { selectedCount - addCount - updateCount }
    var requiredBytes: Int64 { addBytes + updateBytes + sidecarBytes }

    func fits(in freeBytes: Int64?) -> Bool {
        guard let freeBytes else { return true }
        return requiredBytes < freeBytes + removeBytes
    }
}

nonisolated extension SyncPlan {
    var totals: SyncPlanTotals {
        SyncPlanTotals(addCount: requests.count, addBytes: byteCount, updateCount: updates.count,
                       updateBytes: updatedByteCount, removeCount: removals.count, removeBytes: removedByteCount,
                       playlistChangeCount: playlistChangeCount, selectedCount: selectedCount)
    }
}
