import Foundation
import SwiftData

extension NowPlayingSpoken {
    /// `nil` until the episode has been downloaded.
    init?(_ episode: PodcastEpisode) {
        guard let url = episode.downloadedFileURL else { return nil }
        self.init(kind: .episode, id: episode.persistentModelID, collectionTitle: episode.podcast?.title ?? "",
                  artwork: .podcast(episode.podcast?.artworkData),
                  files: [NowPlayingFile(url: url, title: episode.title, duration: episode.duration ?? 0)])
    }

    /// Starts at `file`, or at the file where listening stopped. `nil` for a book without files.
    init?(_ book: Audiobook, startingAt file: AudiobookFile? = nil) {
        let sorted = book.sortedFiles
        guard !sorted.isEmpty else { return nil }
        let startPath = file?.filePath ?? book.currentFilePath
        let artworkFile = book.artworkFile
        self.init(kind: .audiobook, id: book.persistentModelID, collectionTitle: book.title,
                  artwork: .embedded(path: artworkFile?.filePath, fingerprint: artworkFile?.artworkFingerprint),
                  files: sorted.map { NowPlayingFile(url: $0.fileURL, title: $0.title, duration: $0.duration) },
                  index: sorted.firstIndex { $0.filePath == startPath } ?? 0)
    }
}
