import Foundation

/// How much of one kind of content, such as songs or podcasts, a device should hold.
nonisolated enum SyncScope: String, CaseIterable, Codable, Identifiable, Sendable {
    case all
    case selected
    case none

    var id: Self { self }

    func includes(_ key: String, in selection: Set<String>) -> Bool {
        switch self {
        case .all: true
        case .selected: selection.contains(key)
        case .none: false
        }
    }
}
