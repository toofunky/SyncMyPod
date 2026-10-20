import Foundation

/// Finds synced episodes whose download was removed, or audiobook files gone from the audiobook folder, so their
/// copies come off the device too. Unlike music, nothing needs to remain for this to work, but an unplugged drive
/// still removes nothing.
nonisolated struct PodcastMissingSourceFinder {
    let folderPath: String?

    func missing(_ paths: some Sequence<String>, downloaded: Set<String>) -> Set<String> {
        guard let folderPath, FileManager.default.fileExists(atPath: folderPath) else { return [] }
        let root = folderPath.hasSuffix("/") ? folderPath : folderPath + "/"
        return Set(paths.filter {
            $0.hasPrefix(root) && !downloaded.contains($0) && !FileManager.default.fileExists(atPath: $0)
        })
    }
}
