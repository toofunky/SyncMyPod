import Foundation

/// A mounted volume set up as a digital audio player.
nonisolated struct AudioPlayerDevice: Identifiable, Equatable, Sendable {
    let volumeURL: URL
    let volumeName: String
    let capacityBytes: Int64?
    let availableBytes: Int64?
    let config: AudioPlayerConfig

    var id: String { config.id }
    var controlFiles: AudioPlayerControlFiles { AudioPlayerControlFiles(volumeURL: volumeURL) }
    var rootURL: URL { url(forPath: config.rootPath) }
    var musicURL: URL { url(forPath: config.musicPath) }
    var playlistURL: URL { url(forPath: config.playlistPath) }
    /// Only a player whose root is its whole volume, like /Volumes/FIIO, is a drive that can be ejected;
    /// a root deeper inside a volume is just a folder.
    var isEjectable: Bool { config.rootPath.isEmpty }

    /// `path` is relative to the volume.
    func url(forPath path: String) -> URL {
        path.isEmpty ? volumeURL : volumeURL.appending(path: path, directoryHint: .inferFromPath)
    }

    init?(scanningVolumeAt url: URL) {
        guard let config = AudioPlayerControlFiles(volumeURL: url).config() else { return nil }
        self.init(volumeURL: url, config: config)
    }

    init(volumeURL: URL, config: AudioPlayerConfig) {
        let values = try? volumeURL.resourceValues(forKeys: [
            .volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey
        ])
        self.init(volumeURL: volumeURL, volumeName: values?.volumeName ?? volumeURL.lastPathComponent,
                  capacityBytes: values?.volumeTotalCapacity.map(Int64.init),
                  availableBytes: values?.volumeAvailableCapacity.map(Int64.init), config: config)
    }

    init(volumeURL: URL, volumeName: String, capacityBytes: Int64?, availableBytes: Int64?,
         config: AudioPlayerConfig) {
        self.volumeURL = volumeURL
        self.volumeName = volumeName
        self.capacityBytes = capacityBytes
        self.availableBytes = availableBytes
        self.config = config
    }

    @concurrent
    static func scan(volumeAt url: URL) async -> AudioPlayerDevice? {
        AudioPlayerDevice(scanningVolumeAt: url)
    }
}

#if DEBUG
nonisolated extension AudioPlayerDevice {
    static let preview = AudioPlayerDevice(
        volumeURL: URL(fileURLWithPath: "/Volumes/FIIO"),
        volumeName: "FIIO",
        capacityBytes: 255_869_321_216,
        availableBytes: 198_401_544_192,
        config: AudioPlayerConfig(id: "preview-player", name: "FiiO M11", rootPath: "",
                                  musicFolder: "Music", playlistFolder: "Playlists")
    )

    /// A player synced to a folder inside a drive, which can't be ejected.
    static let previewFolder = AudioPlayerDevice(
        volumeURL: URL(fileURLWithPath: "/Volumes/Secondary"),
        volumeName: "Secondary",
        capacityBytes: nil,
        availableBytes: nil,
        config: AudioPlayerConfig(id: "preview-folder", name: "Sandbox", rootPath: "Music/Sandbox/Device")
    )
}
#endif
