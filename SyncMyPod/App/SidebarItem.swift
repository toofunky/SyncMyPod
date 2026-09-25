import Foundation

enum SidebarItem: String, CaseIterable, Identifiable {
    case library
    case device

    var id: Self { self }

    var title: String {
        switch self {
        case .library: "Music Library"
        case .device: "iPod"
        }
    }

    var systemImage: String {
        switch self {
        case .library: "music.note.list"
        case .device: "ipod"
        }
    }
}
