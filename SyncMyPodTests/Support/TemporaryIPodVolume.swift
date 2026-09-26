import Foundation

/// A throwaway directory laid out like a mounted iPod, removed when the test finishes.
final class TemporaryIPodVolume {
    let url = FileManager.default.temporaryDirectory
        .appending(path: "SyncMyPodTests-\(UUID().uuidString)", directoryHint: .isDirectory)

    init(database: Data?, musicFolders: [String] = ["F00", "F01"]) throws {
        let manager = FileManager.default
        try manager.createDirectory(at: url.appending(path: "iPod_Control/iTunes"), withIntermediateDirectories: true)
        for folder in musicFolders {
            try manager.createDirectory(at: url.appending(path: "iPod_Control/Music/\(folder)"),
                                        withIntermediateDirectories: true)
        }
        try database?.write(to: databaseURL)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }

    var databaseURL: URL { url.appending(path: "iPod_Control/iTunes/iTunesDB") }

    func makeSourceFile(named name: String = "song.m4a", bytes: Int = 1_024) throws -> URL {
        let source = url.appending(path: name)
        try FileManager.default.createDirectory(at: source.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data((0..<bytes).map { UInt8(truncatingIfNeeded: $0) }).write(to: source)
        return source
    }
}
