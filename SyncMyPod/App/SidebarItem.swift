import Foundation

enum SidebarItem: Hashable, Identifiable {
    case library
    case device
    case playlist(UUID)

    static let fixedItems: [SidebarItem] = [.library, .device]

    var id: Self { self }

    var title: String {
        switch self {
        case .library: "Music Library"
        case .device: "iPod"
        case .playlist: "Playlist"
        }
    }

    var systemImage: String {
        switch self {
        case .library: "music.note.list"
        case .device: "ipod"
        case .playlist: "music.note.list"
        }
    }
}
