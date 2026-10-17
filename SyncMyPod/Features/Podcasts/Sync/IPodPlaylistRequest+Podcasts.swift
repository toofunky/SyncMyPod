import Foundation

nonisolated extension IPodPlaylistRequest {
    /// Fixed, so every sync replaces the same list. Spells "SMPODCST".
    static let podcastsID: UInt64 = 0x5453_4344_4F50_4D53

    /// The iPod's Podcasts list: each podcast's episodes together, oldest first; `nil` when there are none.
    static func podcasts(_ podcasts: [SyncPodcastSnapshot]) -> IPodPlaylistRequest? {
        let episodes = podcasts.flatMap(\.episodes)
        guard !episodes.isEmpty, let created = podcasts.map(\.playlist.createdAt).min() else { return nil }
        return IPodPlaylistRequest(id: podcastsID, name: "Podcasts", createdAt: created, tracks: episodes,
                                   isPodcasts: true)
    }
}
