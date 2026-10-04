import SwiftUI

extension EnvironmentValues {
    /// File paths of the songs in the Favorites playlist, so rows can show a heart without querying.
    @Entry var favoriteTrackPaths: Set<String> = []
}
