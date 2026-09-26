import Foundation

struct FixtureTrack {
    var id: UInt32
    var title: String
    var artist: String
    var album: String
    var location: String
    var durationMilliseconds: UInt32 = 200_000
    var playCount: UInt32 = 0
    var year: UInt32 = 2005
    var dateAddedMacSeconds: UInt32 = 0
    var extraStrings: [UInt32: String] = [:]
}
