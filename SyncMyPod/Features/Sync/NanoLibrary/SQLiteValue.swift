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

    /// Integers as is, reals truncated, anything else 0.
    var integerValue: Int64 {
        switch self {
        case .integer(let value): value
        case .real(let value): Int64(value)
        default: 0
        }
    }

    var realValue: Double {
        switch self {
        case .real(let value): value
        case .integer(let value): Double(value)
        default: 0
        }
    }

    /// `nil` and empty strings are stored as NULL, as iTunes does.
    static func optionalText(_ value: String?) -> SQLiteValue {
        guard let value, !value.isEmpty else { return .null }
        return .text(value)
    }
}
