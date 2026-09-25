import Foundation

/// A real iTunesDB copied from a device to `SyncMyPodTests/Fixtures/iTunesDB` (git-ignored).
nonisolated enum RealDeviceFixture {
    static let data: Data? = {
        let url = URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Fixtures/iTunesDB", directoryHint: .notDirectory)
        return try? Data(contentsOf: url)
    }()
}
