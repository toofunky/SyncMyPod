import Foundation

nonisolated enum SyncCategory: String, CaseIterable, Identifiable, Sendable {
    case albums
    case genres
    case playlists
    case podcasts
    case audiobooks

    var id: Self { self }

    /// For a selection without podcasts and audiobooks.
    static let musicCategories: [SyncCategory] = [.albums, .genres, .playlists]

    var title: String {
        switch self {
        case .albums: "Albums"
        case .genres: "Genres"
        case .playlists: "Playlists"
        case .podcasts: "Podcasts"
        case .audiobooks: "Audiobooks"
        }
    }
}
