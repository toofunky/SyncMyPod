import Foundation
import SwiftUI

extension LibraryPlaylist {
    static let sidebarOrder = [SortDescriptor(\LibraryPlaylist.sortIndex), SortDescriptor(\.createdAt)]

    static func nextSortIndex(after playlists: [LibraryPlaylist]) -> Int {
        (playlists.compactMap(\.sortIndex).max() ?? -1) + 1
    }

    static func move(_ playlists: [LibraryPlaylist], fromOffsets source: IndexSet, toOffset destination: Int) {
        var reordered = playlists
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, playlist) in reordered.enumerated() where playlist.sortIndex != index {
            playlist.sortIndex = index
        }
    }
}
