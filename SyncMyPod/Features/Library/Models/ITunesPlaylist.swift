import Foundation

nonisolated struct ITunesPlaylist: Identifiable, Equatable, Sendable {
    let id: UInt64
    let name: String
    let isMaster: Bool
    let createdAt: Date?
    let trackIDs: [UInt32]
}
