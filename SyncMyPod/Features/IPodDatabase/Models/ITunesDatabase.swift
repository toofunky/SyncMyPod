import Foundation

nonisolated struct ITunesDatabase: Equatable, Sendable {
    let version: UInt32
    let databaseID: UInt64
    let tracks: [ITunesTrack]
    let playlists: [ITunesPlaylist]

    var masterPlaylist: ITunesPlaylist? { playlists.first(where: \.isMaster) }
    var userPlaylists: [ITunesPlaylist] { playlists.filter { !$0.isMaster } }
}

#if DEBUG
nonisolated extension ITunesDatabase {
    static let preview = ITunesDatabase(
        version: 0x19,
        databaseID: 0xA1B2_C3D4_E5F6_0718,
        tracks: [
            .preview(id: 1, title: "Vertigo", artist: "U2", album: "How to Dismantle an Atomic Bomb",
                     duration: 194, playCount: 42),
            .preview(id: 2, title: "Clocks", artist: "Coldplay", album: "A Rush of Blood to the Head",
                     duration: 307, playCount: 17),
            .preview(id: 3, title: "Hey Ya!", artist: "OutKast", album: "Speakerboxxx/The Love Below",
                     duration: 235, playCount: 8)
        ],
        playlists: [
            ITunesPlaylist(id: 1, name: "Michael's iPod", isMaster: true, createdAt: nil, trackIDs: [1, 2, 3]),
            ITunesPlaylist(id: 2, name: "Road Trip", isMaster: false, createdAt: nil, trackIDs: [1, 3])
        ]
    )
}
#endif
