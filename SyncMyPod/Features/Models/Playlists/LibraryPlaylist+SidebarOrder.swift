import Foundation
import SwiftData
import SwiftUI

extension LibraryPlaylist {
    static let sidebarOrder = [SortDescriptor(\LibraryPlaylist.sortIndex), SortDescriptor(\.createdAt)]

    static func nextSortIndex(after playlists: [LibraryPlaylist]) -> Int {
        (playlists.compactMap(\.sortIndex).max() ?? -1) + 1
    }

    /// Favorites stays first whatever is dropped above it.
    static func move(_ playlists: [LibraryPlaylist], fromOffsets source: IndexSet, toOffset destination: Int) {
        var reordered = playlists
        reordered.move(fromOffsets: source, toOffset: destination)
        let favoritesFirst = reordered.filter(\.isFavorites) + reordered.filter { !$0.isFavorites }
        for (index, playlist) in favoritesFirst.enumerated() where playlist.sortIndex != index {
            playlist.sortIndex = index
        }
    }

    /// Gives playlists made without a position one at the end, in the order they were made, and puts Favorites
    /// above them all.
    static func repairOrder(in context: ModelContext) {
        let descriptor = FetchDescriptor<LibraryPlaylist>(sortBy: [SortDescriptor(\.createdAt)])
        guard let playlists = try? context.fetch(descriptor) else { return }
        let others = playlists.filter { !$0.isFavorites }
        var next = nextSortIndex(after: others)
        for playlist in others where playlist.sortIndex == nil {
            playlist.sortIndex = next
            next += 1
        }
        let lowest = others.compactMap(\.sortIndex).min() ?? 0
        for favorites in playlists where favorites.isFavorites && (favorites.sortIndex ?? lowest) >= lowest {
            favorites.sortIndex = lowest - 1
        }
    }
}
