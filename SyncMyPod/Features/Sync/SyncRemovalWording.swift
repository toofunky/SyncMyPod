import Foundation

/// The question a sync asks before removing songs and podcast episodes from a device.
nonisolated enum SyncRemovalWording {
    /// "Remove 2 songs and 1 episode from the iPod?"
    static func title(songs: Int, episodes: Int, deviceKind: String) -> String {
        let counts = [count(songs, "song"), count(episodes, "episode")].compactMap { $0 }
        return "Remove \(counts.isEmpty ? "0 songs" : counts.joined(separator: " and ")) from the \(deviceKind)?"
    }

    private static func count(_ number: Int, _ noun: String) -> String? {
        number == 0 ? nil : "\(number) \(noun)\(number == 1 ? "" : "s")"
    }
}
