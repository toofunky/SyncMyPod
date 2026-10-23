import Foundation

enum HelpTopic: String, CaseIterable, Identifiable, Sendable {
    case gettingStarted
    case musicLibrary
    case tagEditor
    case playlists
    case podcasts
    case audiobooks
    case syncing
    case audioPlayer
    case troubleshooting

    var id: Self { self }

    var title: String {
        switch self {
        case .gettingStarted: "Getting Started"
        case .musicLibrary: "Music Library"
        case .tagEditor: "Tag Editor"
        case .playlists: "Playlists"
        case .podcasts: "Podcasts"
        case .audiobooks: "Audiobooks"
        case .syncing: "Syncing Your iPod"
        case .audioPlayer: "Syncing Your Audio Player"
        case .troubleshooting: "Troubleshooting"
        }
    }

    var systemImage: String {
        switch self {
        case .gettingStarted: "star"
        case .musicLibrary: "music.note.house"
        case .tagEditor: "tag"
        case .playlists: "music.note.list"
        case .podcasts: "antenna.radiowaves.left.and.right"
        case .audiobooks: "book.closed"
        case .syncing: "arrow.triangle.2.circlepath"
        case .audioPlayer: "headphones"
        case .troubleshooting: "wrench.and.screwdriver"
        }
    }
}
