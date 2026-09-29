import Foundation

nonisolated extension NanoLibraryRows {
    static let musicFolder = "iPod_Control/Music"
    /// "FILE" as a big-endian four-character code.
    private static let fileLocationType = 0x4649_4C45

    func locations() -> [SQLiteTableRows] {
        [SQLiteTableRows(table: "base_location", records: [[("id", .int(1)), ("path", .text(Self.musicFolder))]]),
         SQLiteTableRows(table: "location", records: snapshot.items.map { item in
             [("item_pid", .id(item.pid)), ("sub_id", .int(0)), ("base_location_id", .int(1)),
              ("location_type", .int(Self.fileLocationType)),
              ("location", .optionalText(Self.relativeLocation(item.string(.location)))),
              ("extension", .int(item.fileTypeCode)),
              ("kind_id", .int(item.string(.fileType).flatMap { catalog.kindIDs[$0] } ?? 0)),
              ("date_created", .int(NanoTimestamp.seconds(fromLocal: item.dateAdded))),
              ("file_size", .int(item.fileSize))]
         })]
    }

    func itemStats() -> SQLiteTableRows {
        SQLiteTableRows(table: "item_stats", records: snapshot.items.map { item in
            [("item_pid", .id(item.pid)), ("has_been_played", .bool(item.playCount > 0)),
             ("date_played", .int(NanoTimestamp.seconds(fromLocal: item.dateLastPlayed))),
             ("play_count_user", .int(item.playCount)), ("play_count_recent", .int(0)), ("date_skipped", .int(0)),
             ("skip_count_user", .int(item.skipCount)), ("skip_count_recent", .int(0)),
             ("bookmark_time_ms", .real(0)), ("bookmark_time_ms_common", .real(0)),
             ("user_rating", .int(item.rating)), ("user_rating_common", .int(item.rating))]
        })
    }

    /// ":iPod_Control:Music:F01:ABCD.mp3" → "F01/ABCD.mp3", relative to `musicFolder`.
    static func relativeLocation(_ location: String?) -> String? {
        guard let location else { return nil }
        let path = location.split(separator: ":").joined(separator: "/")
        let prefix = musicFolder + "/"
        return path.hasPrefix(prefix) ? String(path.dropFirst(prefix.count)) : path
    }
}
