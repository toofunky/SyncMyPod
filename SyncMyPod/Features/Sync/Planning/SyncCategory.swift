import Foundation

nonisolated enum SyncCategory: String, CaseIterable, Identifiable, Sendable {
    case albums
    case genres
    case playlists
    case podcasts

    var id: Self { self }

    /// iPods don't sync podcasts yet.
    static let musicCategories: [SyncCategory] = [.albums, .genres, .playlists]

    var title: String {
        switch self {
        case .albums: "Albums"
        case .genres: "Genres"
        case .playlists: "Playlists"
        case .podcasts: "Podcasts"
        }
    }
}
