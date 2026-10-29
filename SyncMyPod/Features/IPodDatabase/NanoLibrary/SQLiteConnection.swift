import Foundation
import SQLite3

/// A minimal SQLite handle for building the nano's library files; not shared across tasks.
nonisolated final class SQLiteConnection {
    private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    private var handle: OpaquePointer?

    /// Replaces any file already at `url`.
    convenience init(creatingAt url: URL) throws {
        try? FileManager.default.removeItem(at: url)
        try self.init(openingAt: url)
    }

    init(openingAt url: URL) throws {
        guard sqlite3_open(url.path(percentEncoded: false), &handle) == SQLITE_OK else {
            let message = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "open failed"
            sqlite3_close(handle)
            throw SQLiteError(message: message)
        }
    }

    deinit { sqlite3_close(handle) }

    func execute(_ sql: String) throws {
        var error: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(handle, sql, nil, nil, &error) == SQLITE_OK else {
            let message = error.map { String(cString: $0) } ?? "unknown error"
            sqlite3_free(error)
            throw SQLiteError(message: message)
        }
    }

    /// Inserts each row, whose values follow the order of `columns`.
    func insert(into table: String, columns: [String], rows: [[SQLiteValue]]) throws {
        let placeholders = Array(repeating: "?", count: columns.count).joined(separator: ",")
        let sql = "INSERT INTO \(table) (\(columns.joined(separator: ","))) VALUES (\(placeholders))"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else { throw lastError() }
        defer { sqlite3_finalize(statement) }
        for row in rows {
            for (index, value) in row.enumerated() { bind(value, at: Int32(index + 1), in: statement) }
            guard sqlite3_step(statement) == SQLITE_DONE else { throw lastError() }
            sqlite3_reset(statement)
            sqlite3_clear_bindings(statement)
        }
    }

    func rows(_ sql: String) throws -> [[SQLiteValue]] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else { throw lastError() }
        defer { sqlite3_finalize(statement) }
        var rows: [[SQLiteValue]] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            rows.append((0..<sqlite3_column_count(statement)).map { column(Int32($0), of: statement) })
        }
        return rows
    }

    private func column(_ index: Int32, of statement: OpaquePointer?) -> SQLiteValue {
        switch sqlite3_column_type(statement, index) {
        case SQLITE_INTEGER: .integer(sqlite3_column_int64(statement, index))
        case SQLITE_FLOAT: .real(sqlite3_column_double(statement, index))
        case SQLITE_TEXT: .text(String(cString: sqlite3_column_text(statement, index)))
        case SQLITE_BLOB:
            .blob(Data(bytes: sqlite3_column_blob(statement, index), count: Int(sqlite3_column_bytes(statement, index))))
        default: .null
        }
    }

    private func bind(_ value: SQLiteValue, at index: Int32, in statement: OpaquePointer?) {
        switch value {
        case .integer(let number): sqlite3_bind_int64(statement, index, number)
        case .real(let number): sqlite3_bind_double(statement, index, number)
        case .text(let text): sqlite3_bind_text(statement, index, text, -1, Self.transient)
        case .blob(let data):
            _ = data.withUnsafeBytes { sqlite3_bind_blob(statement, index, $0.baseAddress, Int32($0.count), Self.transient) }
        case .null: sqlite3_bind_null(statement, index)
        }
    }

    private func lastError() -> SQLiteError {
        SQLiteError(message: String(cString: sqlite3_errmsg(handle)))
    }
}
