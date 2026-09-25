import Foundation

nonisolated enum IPodSyncResult: Equatable, Sendable {
    case added(count: Int, skipped: Int)
    case failed(String)

    var title: String {
        switch self {
        case .added: "Added to iPod"
        case .failed: "Couldn't Add to iPod"
        }
    }

    var message: String {
        switch self {
        case .added(let count, 0):
            "Added \(count) \(count == 1 ? "song" : "songs"). Eject the iPod before unplugging it."
        case .added(let count, let skipped):
            "Added \(count) and skipped \(skipped) already on the iPod. Eject the iPod before unplugging it."
        case .failed(let message):
            message
        }
    }
}
