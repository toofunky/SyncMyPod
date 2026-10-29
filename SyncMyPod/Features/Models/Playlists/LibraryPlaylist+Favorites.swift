import Foundation
import SwiftData

extension LibraryPlaylist {
    static let favoritesFilter = #Predicate<LibraryPlaylist> { $0.isFavoritesFlag == true }

    /// Creates the Favorites playlist at the top of the list if the library doesn't have one yet.
    @discardableResult
    static func ensureFavorites(in context: ModelContext) -> LibraryPlaylist {
        let descriptor = FetchDescriptor(predicate: favoritesFilter)
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let favorites = LibraryPlaylist(name: favoritesName)
        favorites.isFavoritesFlag = true
        favorites.sortIndex = -1
        context.insert(favorites)
        return favorites
    }

    func isFavorite(_ track: LibraryTrack) -> Bool {
        trackPaths.contains(track.filePath)
    }

    /// Favoriting skips songs already here; unfavoriting removes every copy.
    func setFavorite(_ tracks: [LibraryTrack], _ isFavorite: Bool) {
        let paths = tracks.map(\.filePath)
        if isFavorite {
            var existing = Set(trackPaths)
            trackPaths += paths.filter { existing.insert($0).inserted }
        } else {
            let removed = Set(paths)
            trackPaths.removeAll { removed.contains($0) }
        }
    }
}
