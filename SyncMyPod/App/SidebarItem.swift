import Foundation

enum SidebarItem: Hashable, Identifiable {
    case library(LibrarySection)
    case device
    case playlists

    static let allItems = LibrarySection.allCases.map(SidebarItem.library) + [.playlists, .device]

    var id: Self { self }

    var title: String {
        switch self {
        case .library(let section): section.title
        case .device: "iPod"
        case .playlists: "Playlists"
        }
    }

    var systemImage: String {
        switch self {
        case .library(let section): section.systemImage
        case .device: "ipod"
        case .playlists: "music.note.list"
        }
    }
}
