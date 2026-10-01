import Foundation

enum SidebarItem: Hashable, Identifiable {
    case library
    case device
    case playlists

    static let fixedItems: [SidebarItem] = [.library, .playlists, .device]

    var id: Self { self }

    var title: String {
        switch self {
        case .library: "Music Library"
        case .device: "iPod"
        case .playlists: "Playlists"
        }
    }

    var systemImage: String {
        switch self {
        case .library: "music.note"
        case .device: "ipod"
        case .playlists: "music.note.list"
        }
    }
}
