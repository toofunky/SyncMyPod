import Foundation
import Testing
@testable import SyncMyPod

@Suite(.enabled(if: RealDeviceFixture.data != nil, "No real iTunesDB fixture present"))
struct RealDeviceDatabaseTests {
    @Test func parsesRealDatabase() throws {
        let database = try ITunesDBParser(data: try #require(RealDeviceFixture.data)).parse()
        let master = try #require(database.masterPlaylist)
        #expect(!database.tracks.isEmpty)
        #expect(Set(master.trackIDs) == Set(database.tracks.map(\.id)))
        #expect(database.tracks.allSatisfy { $0.location?.hasPrefix(":iPod_Control:") == true })
    }
}
