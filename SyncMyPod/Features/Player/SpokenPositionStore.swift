import Foundation
import SwiftData

/// Saves where listening stopped in an episode or audiobook, unless it has been removed meanwhile.
enum SpokenPositionStore {
    static func save(_ item: NowPlayingSpoken, position: TimeInterval, in context: ModelContext) {
        switch item.kind {
        case .episode:
            guard let episode: PodcastEpisode = context.registeredModel(for: item.id),
                  !episode.isDeleted else { return }
            episode.playbackPosition = position
        case .audiobook:
            guard let book: Audiobook = context.registeredModel(for: item.id), !book.isDeleted else { return }
            // Back at the very start counts as unstarted, as when the book has been listened to the end.
            let isAtStart = item.index == 0 && position == 0
            book.currentFilePath = isAtStart ? nil : item.currentFile.path
            book.playbackPosition = isAtStart ? 0 : position
        }
        try? context.save()
    }
}
