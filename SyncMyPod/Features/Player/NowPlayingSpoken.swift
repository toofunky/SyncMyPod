import Foundation
import SwiftData

/// The podcast episode or audiobook the player is in, copied so removing it mid-play can't crash the player.
/// An episode is a single file; a book plays its files in order.
struct NowPlayingSpoken {
    enum Kind {
        case episode
        case audiobook
    }

    let kind: Kind
    let id: PersistentIdentifier
    /// The show or the book.
    let collectionTitle: String
    let artwork: NowPlayingArtwork
    private(set) var files: [NowPlayingFile]
    private(set) var index: Int

    init(kind: Kind, id: PersistentIdentifier, collectionTitle: String, artwork: NowPlayingArtwork,
         files: [NowPlayingFile], index: Int = 0) {
        self.kind = kind
        self.id = id
        self.collectionTitle = collectionTitle
        self.artwork = artwork
        self.files = files
        self.index = files.indices.contains(index) ? index : 0
    }

    var currentFile: NowPlayingFile { files[index] }

    /// Moves on to the next file, if there is one.
    mutating func advance() -> Bool {
        guard index + 1 < files.count else { return false }
        index += 1
        return true
    }

    mutating func rewind() {
        index = 0
    }

    /// Feeds often leave out an episode's duration, so it's filled in once the file has been read.
    mutating func setDuration(_ duration: TimeInterval, of url: URL) {
        guard let fileIndex = files.firstIndex(where: { $0.url == url }) else { return }
        files[fileIndex].duration = duration
    }
}
