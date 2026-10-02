import Foundation

/// An album artist, or the track artist for songs without one, as the iPod groups them.
nonisolated struct LibraryArtist: Identifiable, Hashable, Sendable {
    let id: String
    let sortName: String
    let albumCount: Int

    var name: String { id }

    var albumCountText: String { albumCount == 1 ? "1 album" : "\(albumCount) albums" }
}
