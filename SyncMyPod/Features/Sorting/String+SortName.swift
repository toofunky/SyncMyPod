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

    /// The file's sort tag when it has one, otherwise `sortName`.
    func sortName(tagged tag: String?) -> String {
        guard let tag, !tag.isEmpty else { return sortName }
        return tag
    }

    /// The sort string iTunes would write to the iPod: the file's sort tag, or one generated without a leading
    /// article, or `""` when the plain value already sorts correctly.
    func iPodSortValue(tagged tag: String?) -> String {
        if let tag, !tag.isEmpty { return tag }
        let generated = sortName
        return generated == self ? "" : generated
    }
}
