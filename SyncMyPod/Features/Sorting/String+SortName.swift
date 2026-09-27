import Foundation

nonisolated extension String {
    /// The string without a leading "A", "An" or "The", so "The Killers" sorts among the K names.
    var sortName: String {
        for article in ["The ", "An ", "A "] {
            guard let range = range(of: article, options: [.anchored, .caseInsensitive]) else { continue }
            let remainder = self[range.upperBound...].drop(while: \.isWhitespace)
            return remainder.isEmpty ? self : String(remainder)
        }
        return self
    }
}
