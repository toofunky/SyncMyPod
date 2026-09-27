import Foundation

/// Matches when any field contains the whole trimmed text, ignoring case and diacritics.
nonisolated struct TrackSearchQuery: Sendable {
    private let text: String

    init(_ text: String) {
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func matches(_ fields: String...) -> Bool {
        text.isEmpty || fields.contains { $0.localizedStandardContains(text) }
    }
}
