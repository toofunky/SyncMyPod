import Foundation

/// Rows for one table, each written as column/value pairs so names sit next to the values they describe.
nonisolated struct SQLiteTableRows: Sendable {
    typealias Record = [(column: String, value: SQLiteValue)]

    let table: String
    let records: [Record]

    func insert(into connection: SQLiteConnection) throws {
        guard let first = records.first else { return }
        try connection.insert(into: table, columns: first.map(\.column), rows: records.map { $0.map(\.value) })
    }
}
