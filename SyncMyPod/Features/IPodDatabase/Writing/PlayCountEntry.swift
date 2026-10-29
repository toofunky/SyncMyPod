import Foundation

/// Listening activity the iPod recorded for one track since the last sync.
nonisolated struct PlayCountEntry: Equatable, Sendable {
    var playCount: UInt32 = 0
    var lastPlayed: UInt32 = 0
    var bookmark: UInt32 = 0
    var rating: UInt32?
    var skipCount: UInt32 = 0
    var lastSkipped: UInt32 = 0
}
