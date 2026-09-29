import Foundation

/// Copies what the nano itself records, or what only iTunes knows, from the library already on the device into
/// a freshly generated one, for tracks and playlists that are still there. Each step is best effort: an old or
/// damaged file shouldn't stop a sync.
nonisolated enum NanoLibraryCarryOver {
    private static let statsColumns = "item_pid, has_been_played, date_played, play_count_user, play_count_recent, "
        + "date_skipped, skip_count_user, skip_count_recent, bookmark_time_ms, bookmark_time_ms_common, "
        + "user_rating, user_rating_common"

    /// `connection` has the new files attached as `dynamic` and `extras`; `previous` is the device's
    /// `iTunes Library.itlp` folder. SQLite can't attach inside a transaction, so this attaches, copies in its
    /// own transaction, then detaches so the device's commands can't resolve a table name to the old copy.
    static func apply(from previous: URL, into connection: SQLiteConnection) throws {
        let attached = attach(previous, to: connection)
        defer { attached.forEach { try? connection.execute("DETACH DATABASE \($0)") } }
        try connection.execute("BEGIN")
        for statement in statements(for: Set(attached)) {
            try? connection.execute(statement)
        }
        try connection.execute("COMMIT")
    }

    private static func attach(_ previous: URL, to connection: SQLiteConnection) -> [String] {
        let files: [(NanoLibraryFile, String)] = [(.library, "old_library"), (.dynamic, "old_dynamic"),
                                                   (.extras, "old_extras")]
        return files.compactMap { file, alias in
            let url = previous.appending(path: file.fileName, directoryHint: .notDirectory)
            guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return nil }
            return (try? connection.execute("ATTACH DATABASE '\(escaped(url))' AS \(alias)")) == nil ? nil : alias
        }
    }

    private static func statements(for attached: Set<String>) -> [String] {
        let items = "item_pid IN (SELECT pid FROM main.item)"
        var statements: [String] = []
        if attached.contains("old_dynamic") {
            statements += [
                "INSERT OR REPLACE INTO dynamic.item_stats (\(statsColumns)) SELECT \(statsColumns) FROM old_dynamic.item_stats WHERE \(items)",
                "INSERT OR REPLACE INTO dynamic.container_ui SELECT * FROM old_dynamic.container_ui WHERE container_pid IN (SELECT pid FROM main.container)"
            ]
        }
        if attached.contains("old_extras") {
            statements += ["lyrics", "chapter"].map { "INSERT OR REPLACE INTO extras.\($0) SELECT * FROM old_extras.\($0) WHERE \(items)" }
        }
        if attached.contains("old_library") {
            statements += ["store_info", "video_info", "podcast_info"].map {
                "INSERT OR REPLACE INTO main.\($0) SELECT * FROM old_library.\($0) WHERE \(items)"
            } + ["UPDATE main.db_info SET genius_cuid = (SELECT genius_cuid FROM old_library.db_info LIMIT 1)"]
        }
        return statements
    }

    static func escaped(_ url: URL) -> String {
        url.path(percentEncoded: false).replacingOccurrences(of: "'", with: "''")
    }
}
