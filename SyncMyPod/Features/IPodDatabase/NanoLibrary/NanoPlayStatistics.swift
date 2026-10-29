import Foundation

/// Running totals the nano keeps for one track in Dynamic.itdb, updated as it plays.
nonisolated struct NanoPlayStatistics: Equatable, Sendable {
    var playCount: UInt32 = 0
    /// Seconds since 2001 in UTC, as the SQLite library stores them.
    var lastPlayed: Int64 = 0
    var skipCount: UInt32 = 0
    var lastSkipped: Int64 = 0
    var rating: UInt32 = 0
    var bookmarkMilliseconds: UInt32 = 0

    /// Reads every row of `item_stats`, keyed by track database ID; empty if the file is missing or unreadable.
    static func load(from dynamicDatabase: URL) -> [UInt64: NanoPlayStatistics] {
        guard FileManager.default.fileExists(atPath: dynamicDatabase.path(percentEncoded: false)),
              let connection = try? SQLiteConnection(openingAt: dynamicDatabase),
              let rows = try? connection.rows("SELECT item_pid, play_count_user, date_played, skip_count_user, "
                                              + "date_skipped, user_rating, bookmark_time_ms FROM item_stats") else {
            return [:]
        }
        return Dictionary(rows.compactMap(entry), uniquingKeysWith: { first, _ in first })
    }

    private static func entry(_ row: [SQLiteValue]) -> (UInt64, NanoPlayStatistics)? {
        guard row.count == 7, case .integer(let pid) = row[0] else { return nil }
        let statistics = NanoPlayStatistics(
            playCount: UInt32(clamping: row[1].integerValue), lastPlayed: row[2].integerValue,
            skipCount: UInt32(clamping: row[3].integerValue), lastSkipped: row[4].integerValue,
            rating: UInt32(clamping: row[5].integerValue),
            bookmarkMilliseconds: UInt32(clamping: Int64(row[6].realValue.rounded())))
        return (UInt64(bitPattern: pid), statistics)
    }
}
