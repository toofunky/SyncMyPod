import Foundation

/// The volume and root folder a person picked for a new player.
nonisolated struct AudioPlayerLocation: Identifiable, Equatable, Sendable {
    let volumeURL: URL
    let volumeName: String
    /// Relative to the volume; empty for the volume itself.
    let rootPath: String

    var id: String { volumeURL.path(percentEncoded: false) + "#" + rootPath }
    var displayPath: String { AudioPlayerConfig.join(volumeName, rootPath) }

    /// Refuses the startup disk, whose "eject" would be meaningless, and iPods, which sync as iPods.
    init(folder: URL) throws {
        let values = try folder.resourceValues(forKeys: [.volumeURLKey, .volumeIsRootFileSystemKey, .volumeNameKey])
        guard let volume = values.volume, values.volumeIsRootFileSystem != true else {
            throw PlayerSyncError.startupDisk
        }
        guard !FileManager.default.fileExists(atPath: volume.appending(path: "iPod_Control").path(percentEncoded: false))
        else { throw PlayerSyncError.iPodVolume }
        volumeURL = volume
        volumeName = values.volumeName ?? volume.lastPathComponent
        rootPath = Self.relativePath(of: folder, in: volume)
    }

    init(volumeURL: URL, volumeName: String, rootPath: String) {
        self.volumeURL = volumeURL
        self.volumeName = volumeName
        self.rootPath = rootPath
    }

    #if DEBUG
    static let preview = AudioPlayerLocation(volumeURL: URL(filePath: "/Volumes/FIIO"), volumeName: "FIIO",
                                             rootPath: "")
    #endif

    private static func relativePath(of folder: URL, in volume: URL) -> String {
        let folderParts = folder.standardizedFileURL.pathComponents
        let volumeParts = volume.standardizedFileURL.pathComponents
        guard folderParts.starts(with: volumeParts) else { return "" }
        return AudioPlayerConfig.cleanedPath(folderParts.dropFirst(volumeParts.count).joined(separator: "/"))
    }
}
