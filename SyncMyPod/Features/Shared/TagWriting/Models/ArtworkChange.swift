import Foundation

nonisolated enum ArtworkChange: Equatable, Sendable {
    case keep
    /// The encoded JPEG or PNG bytes to embed.
    case replace(Data)
    case remove
}
