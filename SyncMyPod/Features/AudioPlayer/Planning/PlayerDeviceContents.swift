import Foundation

/// What's on a player now, as far as planning a sync needs to know.
nonisolated struct PlayerDeviceContents: Equatable, Sendable {
    var manifest = PlayerSyncManifest()
    /// Sizes of the manifest's files that are still on the player, keyed by path.
    var presentSizes: [String: Int64] = [:]
    /// The playlist folder's `.m3u8` files, keyed by path.
    var playlists: [String: String] = [:]

    @concurrent
    static func load(from device: AudioPlayerDevice) async -> PlayerDeviceContents {
        let manifest = device.controlFiles.manifest()
        return PlayerDeviceContents(manifest: manifest, presentSizes: sizes(of: manifest, on: device),
                                    playlists: playlists(on: device))
    }

    func planner(for config: AudioPlayerConfig, missingSources: Set<String> = []) -> PlayerSyncPlanner {
        PlayerSyncPlanner(config: config, manifest: manifest, presentSizes: presentSizes,
                          missingSources: missingSources, existingPlaylists: playlists)
    }

    private static func sizes(of manifest: PlayerSyncManifest, on device: AudioPlayerDevice) -> [String: Int64] {
        var sizes: [String: Int64] = [:]
        for entry in manifest.entries.values {
            let values = try? device.url(forPath: entry.path).resourceValues(forKeys: [.fileSizeKey])
            if let size = values?.fileSize { sizes[entry.path] = Int64(size) }
        }
        return sizes
    }

    private static func playlists(on device: AudioPlayerDevice) -> [String: String] {
        let folder = device.playlistURL
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder.path(percentEncoded: false))) ?? []
        var playlists: [String: String] = [:]
        for name in names where name.lowercased().hasSuffix(".m3u8") && !name.hasPrefix(".") {
            let path = AudioPlayerConfig.join(device.config.playlistPath, name)
            playlists[path] = try? String(contentsOf: folder.appending(path: name), encoding: .utf8)
        }
        return playlists
    }
}
