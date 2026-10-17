import Foundation

extension Podcast {
    var syncKey: String { podcastID.uuidString }

    /// Stable across syncs, like a library playlist's, so the podcast's playlist is replaced rather than duplicated.
    var syncPlaylistID: UInt64 {
        withUnsafeBytes(of: podcastID.uuid) { $0.loadUnaligned(as: UInt64.self) }
    }

    /// Downloaded episodes, oldest first; `nil` when none are downloaded, or none an iPod can play.
    func syncSnapshot(forIPod: Bool = false) -> SyncPodcastSnapshot? {
        let episodes = episodes.filter(\.isDownloaded)
            .sorted { ($0.publishedAt ?? .distantPast) < ($1.publishedAt ?? .distantPast) }
            .compactMap { $0.syncRequest(show: title, author: author, forIPod: forIPod) }
        guard !episodes.isEmpty else { return nil }
        let playlist = IPodPlaylistRequest(id: syncPlaylistID, name: title, createdAt: dateAdded, tracks: episodes)
        return SyncPodcastSnapshot(key: syncKey, playlist: playlist)
    }
}
