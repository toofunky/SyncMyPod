import Foundation

extension TagChanges {
    /// The changes for one of the selected songs. Numbers edited on their own keep the song's other
    /// half of the pair, so setting a count across an album keeps each song's track number.
    init(edits: [TagField: String], artwork: ArtworkChange, applyingTo track: LibraryTrack) {
        self.init(title: edits[.title], artist: edits[.artist], album: edits[.album],
                  albumArtist: edits[.albumArtist], composer: edits[.composer], genre: edits[.genre],
                  year: edits[.year].map(TagField.number(from:)),
                  track: Self.pair(edits[.trackNumber], edits[.trackCount], current: track.trackPosition),
                  disc: Self.pair(edits[.discNumber], edits[.discCount], current: track.discPosition),
                  artwork: artwork, sortTitle: edits[.sortTitle], sortArtist: edits[.sortArtist],
                  sortAlbumArtist: edits[.sortAlbumArtist], sortAlbum: edits[.sortAlbum],
                  sortComposer: edits[.sortComposer])
    }

    private static func pair(_ number: String?, _ count: String?, current: TagNumberPair) -> TagNumberPair? {
        guard number != nil || count != nil else { return nil }
        return TagNumberPair(number: number.map(TagField.number(from:)) ?? current.number,
                             count: count.map(TagField.number(from:)) ?? current.count)
    }
}
