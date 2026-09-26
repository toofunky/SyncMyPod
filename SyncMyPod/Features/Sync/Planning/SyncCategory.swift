import Foundation

nonisolated enum SyncCategory: String, CaseIterable, Identifiable, Sendable {
    case albums
    case genres
    case playlists

    var id: Self { self }

    var title: String {
        switch self {
        case .albums: "Albums"
        case .genres: "Genres"
        case .playlists: "Playlists"
        }
    }
}
