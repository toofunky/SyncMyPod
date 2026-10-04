import Foundation

/// How a digital audio player is laid out, saved on the player itself so it's recognized on any Mac.
nonisolated struct AudioPlayerConfig: Codable, Hashable, Sendable {
    let id: String
    var name: String
    /// The root folder relative to the volume; empty for the volume itself.
    var rootPath: String
    /// Relative to the root; empty means the root.
    var musicFolder = ""
    /// Relative to the root; empty means the root.
    var playlistFolder = ""
    /// Names files "01 Title" or "2-05 Title" for players that sort by file name.
    var preserveTrackSorting = false
    /// Tags copies with the album artist as their artist and moves a guest artist into the title.
    var preserveAlbumArtist = false
    /// Copies an album folder's cover.jpg, folder.jpg, cover.png or folder.png beside its songs.
    var copyCovers = false
    /// Scales copied covers down so neither side is larger than `maxCoverSize` pixels.
    var resizeCovers = false
    var maxCoverSize = Self.defaultMaxCoverSize
    /// Copies each song's .lrc lyric file, renamed to match the song's name on the player.
    var copyLyricFiles = false

    static let defaultMaxCoverSize = 300
    static let coverSizeRange = 16...10_000

    /// The size covers are scaled to fit, or `nil` to copy them as they are.
    var coverPixelLimit: Int? { copyCovers && resizeCovers ? maxCoverSize : nil }

    init(id: String = UUID().uuidString, name: String, rootPath: String, musicFolder: String = "",
         playlistFolder: String = "") {
        self.id = id
        self.name = name
        self.rootPath = Self.cleanedPath(rootPath)
        self.musicFolder = Self.cleanedPath(musicFolder)
        self.playlistFolder = Self.cleanedPath(playlistFolder)
    }

    /// With folders cleaned up as typed by hand, and the volume's name when the name was left blank.
    func cleaned(defaultName: String) -> AudioPlayerConfig {
        var config = self
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        config.name = trimmedName.isEmpty ? defaultName : trimmedName
        config.rootPath = Self.cleanedPath(rootPath)
        config.musicFolder = Self.cleanedPath(musicFolder)
        config.playlistFolder = Self.cleanedPath(playlistFolder)
        config.maxCoverSize = min(max(maxCoverSize, Self.coverSizeRange.lowerBound), Self.coverSizeRange.upperBound)
        return config
    }

    /// The music folder relative to the volume.
    var musicPath: String { Self.join(rootPath, musicFolder) }
    /// The playlist folder relative to the volume.
    var playlistPath: String { Self.join(rootPath, playlistFolder) }

    /// Trims spaces and slashes and drops empty, "." and ".." components, so a path can't leave the volume.
    static func cleanedPath(_ path: String) -> String {
        path.split(separator: "/")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0 != "." && $0 != ".." }
            .joined(separator: "/")
    }

    static func join(_ parts: String...) -> String {
        parts.filter { !$0.isEmpty }.joined(separator: "/")
    }
}

nonisolated extension AudioPlayerConfig {
    /// Options missing from a config saved by an older version read as off, so the player is still recognized.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        rootPath = try container.decode(String.self, forKey: .rootPath)
        musicFolder = try container.decodeIfPresent(String.self, forKey: .musicFolder) ?? ""
        playlistFolder = try container.decodeIfPresent(String.self, forKey: .playlistFolder) ?? ""
        preserveTrackSorting = try container.decodeIfPresent(Bool.self, forKey: .preserveTrackSorting) ?? false
        preserveAlbumArtist = try container.decodeIfPresent(Bool.self, forKey: .preserveAlbumArtist) ?? false
        copyCovers = try container.decodeIfPresent(Bool.self, forKey: .copyCovers) ?? false
        resizeCovers = try container.decodeIfPresent(Bool.self, forKey: .resizeCovers) ?? false
        maxCoverSize = try container.decodeIfPresent(Int.self, forKey: .maxCoverSize) ?? Self.defaultMaxCoverSize
        copyLyricFiles = try container.decodeIfPresent(Bool.self, forKey: .copyLyricFiles) ?? false
    }
}
