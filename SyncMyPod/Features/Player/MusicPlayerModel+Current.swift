import Foundation
import SwiftData

extension MusicPlayerModel {
    func isCurrent(_ track: LibraryTrack) -> Bool {
        currentTrack?.filePath == track.filePath
    }

    func isCurrent(_ episode: PodcastEpisode) -> Bool {
        currentSpoken?.id == episode.persistentModelID
    }

    func isCurrent(_ book: Audiobook) -> Bool {
        currentSpoken?.id == book.persistentModelID
    }

    /// Whether this is the file of the book that's playing.
    func isCurrent(_ file: AudiobookFile) -> Bool {
        currentSpoken?.kind == .audiobook && currentSpoken?.currentFile.path == file.filePath
    }
}
