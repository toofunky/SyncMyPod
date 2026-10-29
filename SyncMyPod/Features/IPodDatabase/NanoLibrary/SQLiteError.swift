import Foundation

nonisolated struct SQLiteError: Error, Equatable, LocalizedError {
    let message: String

    var errorDescription: String? { "The iPod's library database couldn't be written: \(message)" }
}
