import Foundation

/// Ranks distinct sort keys the way iTunes fills the nano's `*_order` columns: ignoring case and accents, 100 apart,
/// with a missing value ranked after every present one.
nonisolated struct NanoSortRanking: Sendable {
    static let step = 100
    /// Unicode collation keeps punctuation significant but below letters, as iTunes does.
    private static let collationLocale = Locale(identifier: "en_US")

    private let ranks: [String: Int]
    private let missingRank: Int

    init<Keys: Sequence>(keys: Keys) where Keys.Element == String? {
        let distinct = Set(keys.compactMap { $0 })
        let sorted = distinct.sorted(by: Self.precedes)
        ranks = Dictionary(uniqueKeysWithValues: sorted.enumerated().map { ($1, $0 + 1) })
        missingRank = sorted.count + 1
    }

    /// The 1-based position of `key`.
    func position(of key: String?) -> Int {
        key.flatMap { ranks[$0] } ?? missingRank
    }

    func order(of key: String?) -> Int {
        position(of: key) * Self.step
    }

    /// Letters sort before digits, which sort before anything else; numbers compare by value.
    static func precedes(_ lhs: String, _ rhs: String) -> Bool {
        let lhsClass = characterClass(lhs), rhsClass = characterClass(rhs)
        if lhsClass != rhsClass { return lhsClass < rhsClass }
        return switch lhs.compare(rhs, options: [.caseInsensitive, .diacriticInsensitive, .numeric], range: nil,
                                  locale: collationLocale) {
        case .orderedAscending: true
        case .orderedDescending: false
        case .orderedSame: lhs < rhs
        }
    }

    private static func characterClass(_ string: String) -> Int {
        guard let first = string.first else { return 0 }
        return first.isLetter ? 0 : first.isNumber ? 1 : 2
    }
}
