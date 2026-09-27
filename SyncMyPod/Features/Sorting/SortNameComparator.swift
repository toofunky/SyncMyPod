import Foundation

/// Compares strings by `sortName`, ignoring a leading "A", "An" or "The".
nonisolated struct SortNameComparator: SortComparator, Sendable {
    var order: SortOrder = .forward

    func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        order == .forward
            ? lhs.sortName.localizedStandardCompare(rhs.sortName)
            : rhs.sortName.localizedStandardCompare(lhs.sortName)
    }
}
