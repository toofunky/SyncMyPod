import Foundation

nonisolated enum SQLiteValue: Hashable, Sendable {
    case integer(Int64)
    case real(Double)
    case text(String)
    case blob(Data)
    case null

    /// iPod IDs are unsigned 64-bit; SQLite stores their bit pattern as a signed integer.
    static func id(_ value: UInt64) -> SQLiteValue { .integer(Int64(bitPattern: value)) }

    static func int<T: BinaryInteger>(_ value: T) -> SQLiteValue { .integer(Int64(value)) }

    static func bool(_ value: Bool) -> SQLiteValue { .integer(value ? 1 : 0) }

    /// `nil` and empty strings are stored as NULL, as iTunes does.
    static func optionalText(_ value: String?) -> SQLiteValue {
        guard let value, !value.isEmpty else { return .null }
        return .text(value)
    }
}
