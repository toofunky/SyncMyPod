import Foundation

/// iPod timestamps count seconds since 1904-01-01 in the device's local time.
nonisolated enum ITunesTimestamp {
    private static let macEpochOffset: TimeInterval = 2_082_844_800

    static func seconds(from date: Date, timeZone: TimeZone = .current) -> UInt32 {
        let local = date.timeIntervalSince1970 + TimeInterval(timeZone.secondsFromGMT(for: date))
        return UInt32(clamping: Int64(local + macEpochOffset))
    }
}
