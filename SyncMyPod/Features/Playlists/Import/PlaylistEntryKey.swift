import Foundation

/// Artist folder, album folder, and file name, compared without regard to case or accents.
nonisolated struct PlaylistEntryKey: Hashable {
    let artist: String
    let album: String
    let fileName: String

    init(artist: String, album: String, fileName: String) {
        self.artist = Self.folded(artist)
        self.album = Self.folded(album)
        self.fileName = Self.folded(fileName)
    }

    /// The last three components of `path`; anything before them is ignored.
    init?(path: String) {
        let components = path.split(separator: "/").map(String.init)
        guard components.count >= 3 else { return nil }
        let tail = components.suffix(3)
        self.init(artist: tail[tail.startIndex], album: tail[tail.startIndex + 1], fileName: tail[tail.startIndex + 2])
    }

    /// Keys for the artist and album artist, each as tagged and as a FAT-safe folder name.
    static func keys(for track: LibraryTrack) -> Set<PlaylistEntryKey> {
        let fileName = URL(filePath: track.filePath).lastPathComponent
        let albums = folderNames(for: track.album, fallback: LibraryTrack.unknownAlbum)
        let tagged = [track.artist, track.albumArtist].filter { !$0.isEmpty }
        let artists = (tagged.isEmpty ? [""] : tagged)
            .flatMap { folderNames(for: $0, fallback: LibraryTrack.unknownArtist) }
        return Set(artists.flatMap { artist in
            albums.map { PlaylistEntryKey(artist: artist, album: $0, fileName: fileName) }
        })
    }

    private static func folderNames(for tag: String, fallback: String) -> [String] {
        let safe = PlayerFileNamer.safeComponent(tag, fallback: fallback)
        return tag.isEmpty ? [safe] : [tag, safe]
    }

    /// Tools swap characters FAT can't store for `_`, `;`, or similar, so those all compare equal.
    private static let substitutable = CharacterSet(charactersIn: ":;_/\\*?\"<>|")

    /// Leading and trailing dots get dropped or swapped for `_` depending on the tool, so they're ignored.
    private static let edges = CharacterSet(charactersIn: "._ ")

    private static func folded(_ text: String) -> String {
        let scalars = text.precomposedStringWithCanonicalMapping
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .unicodeScalars.map { substitutable.contains($0) ? "_" : $0 }
        return String(String.UnicodeScalarView(scalars)).trimmingCharacters(in: edges)
    }
}
