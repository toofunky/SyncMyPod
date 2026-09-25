import Foundation

/// Files under `iPod_Control` that a sync reads or cleans up besides the databases.
nonisolated struct IPodControlFiles {
    private static let onTheGoPrefix = "OTGPlaylistInfo"

    let volumeURL: URL

    private var iTunesURL: URL { volumeURL.appending(path: "iPod_Control/iTunes", directoryHint: .isDirectory) }
    var playCountsURL: URL { iTunesURL.appending(path: "Play Counts", directoryHint: .notDirectory) }

    func playCounts() -> [PlayCountEntry]? {
        (try? Data(contentsOf: playCountsURL)).flatMap(PlayCountsFile.parse)
    }

    /// Converts an iTunesDB location (`:iPod_Control:Music:F01:ABCD.m4a`) to a file URL.
    func fileURL(forLocation location: String) -> URL {
        volumeURL.appending(path: location.split(separator: ":").joined(separator: "/"), directoryHint: .notDirectory)
    }

    func totalSize(of locations: [String]) -> Int64 {
        locations.reduce(0) { total, location in
            let values = try? fileURL(forLocation: location).resourceValues(forKeys: [.fileSizeKey])
            return total + Int64(values?.fileSize ?? 0)
        }
    }

    /// Runs after the new databases are written: deletes removed audio, and the position-indexed
    /// Play Counts and On-The-Go files that no longer line up with the track list.
    func cleanUp(removedLocations: [String], playCountsMerged: Bool) {
        let manager = FileManager.default
        removedLocations.forEach { try? manager.removeItem(at: fileURL(forLocation: $0)) }
        if playCountsMerged || !removedLocations.isEmpty { try? manager.removeItem(at: playCountsURL) }
        guard !removedLocations.isEmpty else { return }
        let names = (try? manager.contentsOfDirectory(atPath: iTunesURL.path(percentEncoded: false))) ?? []
        for name in names where name.hasPrefix(Self.onTheGoPrefix) {
            try? manager.removeItem(at: iTunesURL.appending(path: name))
        }
    }
}
