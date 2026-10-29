import Foundation

/// Which iPod menu lists a track: with the music, under Podcasts, or under Audiobooks.
nonisolated enum ITunesMediaKind: Equatable, Sendable {
    case music
    case podcast
    case audiobook
}
