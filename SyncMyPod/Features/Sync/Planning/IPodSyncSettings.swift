import Foundation
import SwiftData

/// What to sync to one iPod, remembered per device.
@Model
nonisolated final class IPodSyncSettings {
    @Attribute(.unique) var deviceID: String
    /// The single "allSongs" or "custom" choice made before each kind of content had its own scope.
    var modeRawValue = "allSongs"
    /// Optional, like the scopes below, because settings saved before per-tab scopes hold `NULL`.
    var songScopeValue: String?
    var playlistScopeValue: String?
    var podcastScopeValue: String?
    var audiobookScopeValue: String?
    var selectedAlbumKeys: [String] = []
    /// Optional because settings saved before playlists synced hold `NULL`.
    var selectedPlaylistKeys: [String]?
    /// Optional because settings saved before genres synced hold `NULL`.
    var selectedGenreKeys: [String]?
    /// Optional because settings saved before podcasts synced hold `NULL`.
    var selectedPodcastKeys: [String]?
    /// Optional because settings saved before audiobooks synced hold `NULL`.
    var selectedAudiobookKeys: [String]?
    /// Optional because settings saved before this option existed hold `NULL`.
    var preserveAlbumArtistValue: Bool?
    /// Optional, like `preserveAlbumArtistValue`, because settings saved before this option existed hold `NULL`.
    var syncLyricsSidecarValue: Bool?
    /// Optional, like `preserveAlbumArtistValue`, because settings saved before this option existed hold `NULL`.
    var makeAudiobookPlaylistsValue: Bool?

    init(deviceID: String) {
        self.deviceID = deviceID
    }

    var songScope: SyncScope {
        get { scope(songScopeValue) }
        set { songScopeValue = newValue.rawValue }
    }

    var playlistScope: SyncScope {
        get { scope(playlistScopeValue) }
        set { playlistScopeValue = newValue.rawValue }
    }

    var podcastScope: SyncScope {
        get { scope(podcastScopeValue) }
        set { podcastScopeValue = newValue.rawValue }
    }

    var audiobookScope: SyncScope {
        get { scope(audiobookScopeValue) }
        set { audiobookScopeValue = newValue.rawValue }
    }

    /// A scope never chosen follows the old single choice, so a device syncs what it did before.
    private func scope(_ rawValue: String?) -> SyncScope {
        rawValue.flatMap(SyncScope.init(rawValue:)) ?? (modeRawValue == "custom" ? .selected : .all)
    }

    var preservesAlbumArtist: Bool {
        get { preserveAlbumArtistValue ?? false }
        set { preserveAlbumArtistValue = newValue }
    }

    var syncsLyricsSidecars: Bool {
        get { syncLyricsSidecarValue ?? false }
        set { syncLyricsSidecarValue = newValue }
    }

    /// On unless turned off, since the iPod's Audiobooks menu mixes every book's parts together.
    var makesAudiobookPlaylists: Bool {
        get { makeAudiobookPlaylistsValue ?? true }
        set { makeAudiobookPlaylistsValue = newValue }
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

    var selectedPodcasts: Set<String> {
        get { Set(selectedPodcastKeys ?? []) }
        set { selectedPodcastKeys = newValue.sorted() }
    }

    var selectedAudiobooks: Set<String> {
        get { Set(selectedAudiobookKeys ?? []) }
        set { selectedAudiobookKeys = newValue.sorted() }
    }

    var selection: SyncSelection {
        SyncSelection(songs: songScope, playlistScope: playlistScope, podcastScope: podcastScope,
                      audiobookScope: audiobookScope, albums: selectedAlbums, genres: selectedGenres,
                      playlists: selectedPlaylists, podcasts: selectedPodcasts, audiobooks: selectedAudiobooks)
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
