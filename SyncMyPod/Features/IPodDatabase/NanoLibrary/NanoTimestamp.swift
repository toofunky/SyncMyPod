import Foundation

/// Converts iTunesDB timestamps (seconds since 1904 in local time) to the nano's SQLite ones
/// (seconds since 2001 in UTC). Zero means "never" in both.
nonisolated enum NanoTimestamp {
    private static let macToReferenceOffset: Int64 = 3_061_152_000

    static func seconds(fromLocal macSeconds: UInt32, timeZone: TimeZone = .current) -> Int64 {
        guard macSeconds != 0 else { return 0 }
        let local = Int64(macSeconds) - macToReferenceOffset
        let offset = timeZone.secondsFromGMT(for: Date(timeIntervalSinceReferenceDate: TimeInterval(local)))
        return local - Int64(offset)
    }

    /// The inverse of `seconds(fromLocal:)`, for folding the nano's own records back into the iTunesDB.
    static func localMacSeconds(from seconds: Int64, timeZone: TimeZone = .current) -> UInt32 {
        guard seconds != 0 else { return 0 }
        let offset = timeZone.secondsFromGMT(for: Date(timeIntervalSinceReferenceDate: TimeInterval(seconds)))
        return UInt32(clamping: seconds + Int64(offset) + macToReferenceOffset)
    }

    /// Release dates are stored in UTC even in the iTunesDB.
    static func seconds(fromUTC macSeconds: UInt32) -> Int64 {
        macSeconds == 0 ? 0 : Int64(macSeconds) - macToReferenceOffset
    }
}
