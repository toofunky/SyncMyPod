import Foundation
import Testing
@testable import SyncMyPod

struct DeviceSyncResultTests {
    @Test func summaryCountsTheIPodOutcome() {
        var outcome = IPodSyncOutcome(addedDatabaseIDs: ["/a.m4a": 1, "/b.m4a": 2], updatedDatabaseIDs: ["/c.m4a": 3],
                                      skipped: 4, removed: 5, syncedPlaylistCount: 1)
        outcome.wasCancelled = true
        let summary = SyncSummary(outcome)
        #expect(summary == SyncSummary(added: 2, updated: 1, removed: 5, skipped: 4, syncedPlaylistCount: 1,
                                       wasCancelled: true, deviceKind: "iPod"))
        #expect(summary.changedCount == 9)
    }

    @Test func finishedMessageNamesTheDeviceKind() {
        let result = DeviceSyncResult.finished(SyncSummary(added: 1, skipped: 2, deviceKind: "Player"))
        #expect(result.title == "Sync Complete")
        #expect(result.message == "Added 1 song. 2 already on the Player. Eject the Player before unplugging it.")
    }

    @Test func unchangedSyncDoesNotAskForAnEject() {
        let result = DeviceSyncResult.finished(SyncSummary(skipped: 3, deviceKind: "iPod"))
        #expect(result.message == "Added 0 songs. 3 already on the iPod.")
    }

    @Test func failureAndCancellationTitles() {
        #expect(DeviceSyncResult.failed("Disk full", deviceKind: "iPod").title == "Couldn't Sync iPod")
        #expect(DeviceSyncResult.finished(SyncSummary(wasCancelled: true, deviceKind: "iPod")).title == "Sync Cancelled")
    }
}
