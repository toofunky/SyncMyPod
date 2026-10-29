import Foundation

/// Identifies the same song on the Mac and on an iPod, whichever app copied it there.
nonisolated struct IPodTrackMatchKey: Hashable, Sendable {
    let title: String
    let artist: String
    let album: String
    let fileSize: Int

    init(title: String, artist: String, album: String, fileSize: Int) {
        self.title = Self.normalized(title)
        self.artist = Self.normalized(artist)
        self.album = Self.normalized(album)
        self.fileSize = fileSize
    }

    init(_ draft: ITunesTrackDraft) {
        self.init(title: draft.title, artist: draft.artist, album: draft.album, fileSize: draft.fileSize)
    }

    init(_ track: ITunesTrack) {
        self.init(title: track.title, artist: track.artist, album: track.album, fileSize: track.fileSize)
    }

    static func keys(in database: ITunesDatabase) -> Set<IPodTrackMatchKey> {
        Set(database.tracks.map(IPodTrackMatchKey.init))
    }

    private static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
