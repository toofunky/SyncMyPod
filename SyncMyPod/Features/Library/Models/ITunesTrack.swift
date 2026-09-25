import Foundation

nonisolated struct ITunesTrack: Identifiable, Equatable, Sendable {
    let id: UInt32
    let databaseID: UInt64
    let strings: [ITunesStringField: String]
    let duration: TimeInterval
    let fileSize: Int
    let trackNumber: Int
    let trackCount: Int
    let discNumber: Int
    let discCount: Int
    let year: Int
    let bitrate: Int
    let sampleRate: Int
    let rating: Int
    let playCount: Int
    let mediaType: UInt32?
    let dateAdded: Date?
    let lastPlayed: Date?
    let lastModified: Date?

    var title: String { strings[.title] ?? "" }
    var artist: String { strings[.artist] ?? "" }
    var album: String { strings[.album] ?? "" }
    var genre: String { strings[.genre] ?? "" }
    var location: String? { strings[.location] }

    /// Converts the colon-separated iPod path (":iPod_Control:Music:F00:ABCD.mp3") to a file URL.
    func fileURL(onVolume volumeURL: URL) -> URL? {
        guard let location, !location.isEmpty else { return nil }
        let relativePath = location.split(separator: ":").joined(separator: "/")
        return volumeURL.appending(path: relativePath, directoryHint: .notDirectory)
    }
}

#if DEBUG
nonisolated extension ITunesTrack {
    static func preview(id: UInt32, title: String, artist: String, album: String,
                        duration: TimeInterval, playCount: Int = 0) -> ITunesTrack {
        ITunesTrack(id: id, databaseID: UInt64(id) * 7919,
                    strings: [.title: title, .artist: artist, .album: album],
                    duration: duration, fileSize: 5_000_000, trackNumber: 1, trackCount: 10,
                    discNumber: 1, discCount: 1, year: 2005, bitrate: 256, sampleRate: 44_100,
                    rating: 0, playCount: playCount, mediaType: 1,
                    dateAdded: nil, lastPlayed: nil, lastModified: nil)
    }
}
#endif
