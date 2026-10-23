import Foundation

/// What a synced file is, which decides where a player files it and how an iPod lists it.
nonisolated enum SyncMediaKind: Equatable, Sendable {
    case music
    /// Listed under Podcasts on an iPod, and filed in a player's podcast folder.
    case podcast
    /// Listed under Audiobooks on an iPod, and filed in a player's audiobook folder.
    case audiobook
}
