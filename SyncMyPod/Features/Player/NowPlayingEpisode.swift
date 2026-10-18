import Foundation
import SwiftData

/// What the player shows for the podcast episode it's playing, copied so unsubscribing mid-episode can't crash it.
struct NowPlayingEpisode {
    let id: PersistentIdentifier
    let title: String
    let show: String
    let artworkData: Data?
    let fileURL: URL
    var duration: TimeInterval

    init?(_ episode: PodcastEpisode) {
        guard let fileURL = episode.downloadedFileURL else { return nil }
        id = episode.persistentModelID
        title = episode.title
        show = episode.podcast?.title ?? ""
        artworkData = episode.podcast?.artworkData
        self.fileURL = fileURL
        duration = episode.duration ?? 0
    }
}
