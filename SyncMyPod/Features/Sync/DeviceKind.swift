import Foundation

/// What kind of device a sync is for, as named in its messages.
nonisolated enum DeviceKind: Equatable, Sendable {
    case iPod
    case player

    /// "iPod" or "player", as used mid-sentence.
    var name: String {
        switch self {
        case .iPod: "iPod"
        case .player: "player"
        }
    }

    /// "iPod" or "Player", as used in titles.
    var title: String {
        switch self {
        case .iPod: "iPod"
        case .player: "Player"
        }
    }
}
