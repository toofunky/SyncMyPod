import Foundation
import SwiftData

@Model
nonisolated final class LibraryPlaylist {
    static let untitledName = "Untitled Playlist"

    @Attribute(.unique) var playlistID: UUID
    var name: String
    var createdAt: Date
    /// Library file paths in play order; a song may appear more than once.
    var trackPaths: [String] = []
    /// Position in the sidebar; nil for playlists that have never been reordered.
    var sortIndex: Int?

    init(name: String = LibraryPlaylist.untitledName, trackPaths: [String] = []) {
        playlistID = UUID()
        self.name = name
        createdAt = .now
        self.trackPaths = trackPaths
    }

    func append(_ tracks: [LibraryTrack]) {
        trackPaths += tracks.map(\.filePath)
    }
}

#if DEBUG
extension LibraryPlaylist {
    static let preview = LibraryPlaylist(name: "Road Trip", trackPaths: LibraryTrack.previewTracks.map(\.filePath))
}
#endif
