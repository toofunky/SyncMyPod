import Foundation

/// Reads the song paths out of an `.m3u` or `.m3u8` playlist.
nonisolated enum M3UPlaylistParser {
    private static let trimmed = CharacterSet.whitespaces.union(CharacterSet(charactersIn: "\u{FEFF}"))

    /// UTF-8 first, then the legacy encodings older `.m3u` files use.
    static func read(_ url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        for encoding in [String.Encoding.utf8, .windowsCP1252, .isoLatin1] {
            if let text = String(data: data, encoding: encoding) { return text }
        }
        throw CocoaError(.fileReadInapplicableStringEncoding)
    }

    static func paths(in text: String) -> [String] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: trimmed) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
            .map(normalized)
    }

    /// Decodes `file://` URLs and turns Windows separators into `/`.
    private static func normalized(_ line: String) -> String {
        if line.lowercased().hasPrefix("file://"), let url = URL(string: line) {
            return url.path(percentEncoded: false)
        }
        return line.replacingOccurrences(of: "\\", with: "/")
    }
}
