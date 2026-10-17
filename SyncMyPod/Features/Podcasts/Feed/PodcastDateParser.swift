import Foundation

/// Parses RSS `pubDate`s, which should be RFC 822 but in practice vary in weekday, seconds and time zone style.
nonisolated enum PodcastDateParser {
    private static let formats = [
        "EEE, d MMM yyyy HH:mm:ss Z", "EEE, d MMM yyyy HH:mm:ss zzz", "EEE, d MMM yyyy HH:mm Z",
        "EEE, d MMM yyyy HH:mm zzz", "d MMM yyyy HH:mm:ss Z", "d MMM yyyy HH:mm:ss zzz", "EEE, d MMM yyyy HH:mm:ss"
    ]

    /// Shared because creating a formatter per date is slow for feeds with hundreds of episodes.
    private static let formatters: [DateFormatter] = formats.map { format in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = format
        return formatter
    }

    static func date(from string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if let date = formatters.lazy.compactMap({ $0.date(from: trimmed) }).first { return date }
        return try? Date(trimmed, strategy: .iso8601)
    }
}
