import Foundation

nonisolated enum SyncMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case allSongs
    case custom

    var id: Self { self }

    var title: String {
        switch self {
        case .allSongs: "Sync All Songs"
        case .custom: "Custom Sync"
        }
    }
}
