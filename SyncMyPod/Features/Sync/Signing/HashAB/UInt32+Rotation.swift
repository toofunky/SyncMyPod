import Foundation

nonisolated extension UInt32 {
    /// Only the low five bits of `count` are used, so a count of 0 or 32 leaves the value unchanged.
    func rotatedLeft(_ count: UInt32) -> UInt32 {
        self << (count & 31) | self >> ((32 &- count) & 31)
    }

    func rotatedRight(_ count: UInt32) -> UInt32 {
        self >> (count & 31) | self << ((32 &- count) & 31)
    }
}
