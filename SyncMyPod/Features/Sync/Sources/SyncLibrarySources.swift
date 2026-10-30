import Foundation
import SwiftData

/// The library a device's Sync tab works from, as its view queried it, and the folders it was read from.
struct SyncLibrarySources {
    var tracks: [LibraryTrack] = []
    var playlists: [LibraryPlaylist] = []
    var podcasts: [Podcast] = []
    var audiobooks: [Audiobook] = []
    var musicFolderPath: String?
    var podcastFolderPath: String?
    var audiobookFolderPath: String?

    var isEmpty: Bool { tracks.isEmpty && downloadedEpisodePaths.isEmpty && audiobooks.isEmpty }

    var downloadedEpisodePaths: Set<String> { Set(podcasts.flatMap(\.episodes).compactMap(\.downloadedFilePath)) }
    var audiobookFilePaths: Set<String> { Set(audiobooks.flatMap(\.files).map(\.filePath)) }

    /// Synced episodes whose download was removed and audiobook files gone from the audiobook folder. Nothing
    /// from a folder whose drive is unplugged.
    func removedDownloads(among synced: some Sequence<String>) -> Set<String> {
        let synced = Array(synced)
        return RemovedSourceFinder(folderPath: podcastFolderPath).missing(synced, known: downloadedEpisodePaths)
            .union(RemovedSourceFinder(folderPath: audiobookFolderPath).missing(synced, known: audiobookFilePaths))
    }

    /// Synced songs gone from the library for good. Nothing while the music drive is unplugged.
    func missingSongs(among synced: some Sequence<String>) -> Set<String> {
        guard let musicFolderPath else { return [] }
        return MissingSourceFinder(folderPath: musicFolderPath).missing(synced, notIn: Set(tracks.map(\.filePath)))
    }

    /// Reads the codec and audio details of downloads made before they were recorded, so they're listed correctly
    /// and an iPod knows whether it can play them.
    func readMissingEpisodeDetails(context: ModelContext) async {
        let episodes = podcasts.flatMap(\.episodes).filter { $0.isDownloaded && $0.codecRawValue == nil }
        guard !episodes.isEmpty else { return }
        for episode in episodes {
            guard let url = episode.downloadedFileURL,
                  let metadata = try? await AudioMetadataReader().read(url) else { continue }
            episode.apply(metadata)
        }
        try? context.save()
    }
}
