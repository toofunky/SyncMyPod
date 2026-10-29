import Foundation

nonisolated enum CoverResizeError: Error, Equatable {
    case unreadableImage
    case unwritableImage
}
