import Foundation

nonisolated struct SyncArtistNode: Identifiable, Equatable, Sendable {
    let name: String
    let albums: [SyncAlbumNode]

    var id: String { name }
    var albumKeys: Set<String> { Set(albums.map(\.key)) }
}
