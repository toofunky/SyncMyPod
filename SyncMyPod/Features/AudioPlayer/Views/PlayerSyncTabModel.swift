import Foundation
import Observation
import SwiftData

/// What a player's Sync tab shows: its settings, what's on the player, what's gone from the library, and the
/// covers and lyric files beside the library's songs.
@Observable
@MainActor
final class PlayerSyncTabModel {
    private(set) var settings: DeviceSyncSettings?
    private(set) var contents: PlayerDeviceContents?
    private(set) var missingSources: Set<String> = []
    private(set) var sidecars = LibrarySidecars()
    private(set) var freeBytes: Int64?

    func library(from sources: SyncLibrarySources, for device: AudioPlayerDevice) -> SyncLibrarySnapshot {
        SyncLibrarySnapshot(tracks: sources.tracks, playlists: sources.playlists, podcasts: sources.podcasts,
                            audiobooks: sources.audiobooks, preservingAlbumArtist: device.config.preserveAlbumArtist)
    }

    /// Copies whose library file, download or audiobook file is gone for good are removed; ones on an unplugged
    /// drive are kept.
    func reload(_ sources: SyncLibrarySources, from device: AudioPlayerDevice, context: ModelContext) async {
        await sources.readMissingEpisodeDetails(context: context)
        settings = DeviceSyncSettings.settings(for: device.id, in: context)
        let loaded = await PlayerDeviceContents.load(from: device)
        let synced = loaded.manifest.entries.keys
        missingSources = sources.missingSongs(among: synced).union(sources.removedDownloads(among: synced))
        sidecars = await LibrarySidecarFinder.find(
            besideSongsAt: sources.tracks.map(\.filePath) + sources.audiobookFilePaths.sorted(),
            covers: device.config.copyCovers, lyrics: device.config.copyLyricFiles)
        contents = loaded
        freeBytes = device.volumeURL.volumeAvailableBytes
    }
}
