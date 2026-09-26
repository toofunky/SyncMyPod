import Foundation
import SwiftData

/// What to sync to one iPod, remembered per device.
@Model
nonisolated final class IPodSyncSettings {
    @Attribute(.unique) var deviceID: String
    var modeRawValue = SyncMode.allSongs.rawValue
    var selectedAlbumKeys: [String] = []
    /// Optional because settings saved before playlists synced hold `NULL`.
    var selectedPlaylistKeys: [String]?
    /// Optional because settings saved before genres synced hold `NULL`.
    var selectedGenreKeys: [String]?
    /// Optional because settings saved before this option existed hold `NULL`.
    var preserveAlbumArtistValue: Bool?

    init(deviceID: String) {
        self.deviceID = deviceID
    }

    var mode: SyncMode {
        get { SyncMode(rawValue: modeRawValue) ?? .allSongs }
        set { modeRawValue = newValue.rawValue }
    }

    var preservesAlbumArtist: Bool {
        get { preserveAlbumArtistValue ?? false }
        set { preserveAlbumArtistValue = newValue }
    }

    var selectedAlbums: Set<String> {
        get { Set(selectedAlbumKeys) }
        set { selectedAlbumKeys = newValue.sorted() }
    }

    var selectedPlaylists: Set<String> {
        get { Set(selectedPlaylistKeys ?? []) }
        set { selectedPlaylistKeys = newValue.sorted() }
    }

    var selectedGenres: Set<String> {
        get { Set(selectedGenreKeys ?? []) }
        set { selectedGenreKeys = newValue.sorted() }
    }

    @MainActor
    static func settings(for deviceID: String, in context: ModelContext) -> IPodSyncSettings {
        let descriptor = FetchDescriptor<IPodSyncSettings>(predicate: #Predicate { $0.deviceID == deviceID })
        if let existing = try? context.fetch(descriptor).first { return existing }
        let settings = IPodSyncSettings(deviceID: deviceID)
        context.insert(settings)
        return settings
    }
}
