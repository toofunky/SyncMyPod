import Foundation

enum SidebarItem: Hashable, Identifiable {
    case library(LibrarySection)
    case playlists
    case podcasts
    case audiobooks
    case device(id: String)
    /// Shown in place of the device rows while nothing is connected.
    case noDevice

    static let libraryItems = LibrarySection.allCases.map(SidebarItem.library) + [.playlists, .podcasts, .audiobooks]

    var id: Self { self }

    var isDevice: Bool {
        switch self {
        case .device, .noDevice: true
        case .library, .playlists, .podcasts, .audiobooks: false
        }
    }

    var title: String {
        switch self {
        case .library(let section): section.title
        case .playlists: "Playlists"
        case .podcasts: "Podcasts"
        case .audiobooks: "Audiobooks"
        case .device: "Device"
        case .noDevice: "No Device"
        }
    }

    var systemImage: String {
        switch self {
        case .library(let section): section.systemImage
        case .playlists: "music.note.list"
        case .podcasts: "antenna.radiowaves.left.and.right"
        case .audiobooks: "book.closed"
        case .device, .noDevice: "ipod"
        }
    }

    /// Where the sidebar goes when the selected device is unplugged.
    static func fallback(for selection: SidebarItem?, connectedIDs: [String]) -> SidebarItem? {
        switch selection {
        case .device(let id) where !connectedIDs.contains(id):
            connectedIDs.first.map { .device(id: $0) } ?? .noDevice
        case .noDevice where !connectedIDs.isEmpty:
            .device(id: connectedIDs[0])
        default:
            selection
        }
    }
}
