import Foundation

nonisolated extension SyncPlaylistRequest {
    /// Fixed, so every sync replaces the same list. Spells "SMPODCST".
    static let podcastsID: UInt64 = 0x5453_4344_4F50_4D53

    /// The iPod's Podcasts list: each podcast's episodes together, oldest first; `nil` when there are none.
    static func podcasts(_ podcasts: [SyncPodcastSnapshot]) -> SyncPlaylistRequest? {
        let episodes = podcasts.flatMap(\.episodes)
        guard !episodes.isEmpty, let created = podcasts.map(\.playlist.createdAt).min() else { return nil }
        return SyncPlaylistRequest(id: podcastsID, name: "Podcasts", createdAt: created, tracks: episodes,
                                   isPodcasts: true)
    }
}
