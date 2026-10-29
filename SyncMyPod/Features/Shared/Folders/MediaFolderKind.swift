import Foundation

/// The folders the app scans or downloads into, which must stay apart.
nonisolated enum MediaFolderKind: CaseIterable, Hashable, Sendable {
    case music
    case podcasts
    case audiobooks

    /// "podcast", as in "your podcast folder".
    var name: String {
        switch self {
        case .music: "music"
        case .podcasts: "podcast"
        case .audiobooks: "audiobook"
        }
    }
}
