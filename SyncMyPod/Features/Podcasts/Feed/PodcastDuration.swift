import Foundation

/// Parses `itunes:duration`, written as seconds ("3358") or as "MM:SS" or "HH:MM:SS".
nonisolated enum PodcastDuration {
    static func seconds(from string: String) -> TimeInterval? {
        let parts = string.trimmingCharacters(in: .whitespaces).split(separator: ":", omittingEmptySubsequences: false)
        guard (1...3).contains(parts.count) else { return nil }
        let values = parts.compactMap { Double($0) }
        guard values.count == parts.count, values.allSatisfy({ $0 >= 0 }) else { return nil }
        let seconds = values.reduce(0) { $0 * 60 + $1 }
        return seconds > 0 ? seconds : nil
    }
}
