import Foundation

/// Turns .lrc lyrics into the plain text an iPod shows, dropping header lines such as `[ar:Coldplay]`,
/// line times such as `[01:02.34]` and enhanced LRC's word times such as `<01:02.34>`.
nonisolated enum LRCLyrics {
    static func plainText(from lrc: String) -> String {
        let header = /\s*\[[A-Za-z#]+:[^\]]*\]\s*/
        let time = /[\[<]\d+:\d+(?:[.:]\d+)?[\]>]/
        let lines = lrc.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            .filter { (try? header.wholeMatch(in: $0)) == nil }
            .map { $0.replacing(time, with: "").trimmingCharacters(in: .whitespaces) }
        return lines.drop { $0.isEmpty }.reversed().drop { $0.isEmpty }.reversed().joined(separator: "\n")
    }
}
