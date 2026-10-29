import Foundation

enum LibrarySection: Hashable, CaseIterable {
    case artists
    case albums
    case songs

    var title: String {
        switch self {
        case .artists: "Artists"
        case .albums: "Albums"
        case .songs: "Songs"
        }
    }

    var systemImage: String {
        switch self {
        case .artists: "music.mic"
        case .albums: "square.stack"
        case .songs: "music.note"
        }
    }
}
