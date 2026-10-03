import Foundation

/// File changes on a player's volume, each leaving either the old file or the new one, never half of one.
nonisolated struct PlayerFileOperations {
    private static let ignoredFileNames: Set<String> = [".DS_Store"]

    let device: AudioPlayerDevice
    private var manager: FileManager { .default }

    /// Copies, and retags, beside the destination first, so a cancelled or failed copy never leaves a truncated
    /// or half-tagged song.
    func copy(_ request: IPodSyncRequest, to path: String) async throws {
        let source = request.sourceURL
        guard manager.fileExists(atPath: source.path(percentEncoded: false)) else {
            throw PlayerSyncError.missingSource(source.lastPathComponent)
        }
        let destination = device.url(forPath: path)
        let folder = destination.deletingLastPathComponent()
        try manager.createDirectory(at: folder, withIntermediateDirectories: true)
        let staged = folder.appending(path: ".syncmypod-\(UUID().uuidString).tmp")
        do {
            try manager.copyItem(at: source, to: staged)
            if let tags = request.playerTagChanges {
                try await TagWriter().write(tags, to: staged, codec: request.draft.codec)
            }
            try replace(destination, with: staged)
        } catch {
            try? manager.removeItem(at: staged)
            throw error
        }
    }

    /// Goes through a temporary name when only the case changes, which FAT and exFAT treat as the same name.
    func move(from: String, to: String) throws {
        let source = device.url(forPath: from)
        let destination = device.url(forPath: to)
        try manager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard from.lowercased() == to.lowercased() else { return try replace(destination, with: source) }
        let staged = destination.deletingLastPathComponent().appending(path: ".syncmypod-\(UUID().uuidString).tmp")
        try manager.moveItem(at: source, to: staged)
        try manager.moveItem(at: staged, to: destination)
    }

    /// Missing files count as removed.
    func remove(_ path: String) {
        try? manager.removeItem(at: device.url(forPath: path))
    }

    func write(_ contents: String, to path: String) throws {
        let url = device.url(forPath: path)
        try manager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(contents.utf8).write(to: url, options: .atomic)
    }

    /// Deletes folders left empty below the music folder, apart from Finder's hidden files.
    func pruneEmptyFolders(containing paths: some Sequence<String>) {
        let root = device.config.musicPath
        let prefix = root.isEmpty ? "" : root + "/"
        for path in paths {
            var folder = (path as NSString).deletingLastPathComponent
            while folder.count > root.count, folder.hasPrefix(prefix), isEmptyFolder(folder) {
                try? manager.removeItem(at: device.url(forPath: folder))
                folder = (folder as NSString).deletingLastPathComponent
            }
        }
    }

    private func isEmptyFolder(_ path: String) -> Bool {
        guard let names = try? manager.contentsOfDirectory(atPath: device.url(forPath: path).path(percentEncoded: false))
        else { return false }
        return names.allSatisfy { Self.ignoredFileNames.contains($0) || $0.hasPrefix("._") }
    }

    private func replace(_ destination: URL, with source: URL) throws {
        if manager.fileExists(atPath: destination.path(percentEncoded: false)) {
            try manager.removeItem(at: destination)
        }
        try manager.moveItem(at: source, to: destination)
    }
}
