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

    /// What the category's scope covers. Albums and genres share one scope, over songs.
    var contentTitle: String {
        switch self {
        case .albums, .genres: "Songs"
        default: title
        }
    }

    var systemImage: String {
        switch self {
        case .albums, .genres, .playlists: "music.note.list"
        case .podcasts: "antenna.radiowaves.left.and.right"
        case .audiobooks: "book.closed"
        }
    }
}
