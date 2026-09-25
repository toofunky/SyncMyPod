import Foundation

/// Rewrites an existing track's `mhit` from a draft, keeping its IDs, date added, play statistics, ratings,
/// playlist entries and any strings the draft doesn't describe.
nonisolated enum ITunesDBTrackUpdater {
    private static let databaseIDOffset = 0x70
    private static let albumIDOffset = 0x120
    /// The strings a draft writes, plus sort names that would otherwise contradict the new tags.
    private static let replacedStrings: Set<UInt32> = Set([
        ITunesStringField.title, .location, .album, .artist, .genre, .fileType, .albumArtist,
        .sortArtist, .sortTitle, .sortAlbum, .sortAlbumArtist
    ].map(\.rawValue))

    static func contains(_ databaseID: UInt64, in root: ITunesDBRecord) -> Bool {
        trackList(in: root)?.children.contains { $0.uint64(at: databaseIDOffset) == databaseID } ?? false
    }

    /// Returns the track's previous file location, if it had one.
    static func update(_ databaseID: UInt64, with draft: ITunesTrackDraft, albumID: UInt32, keepingArtwork: Bool,
                       builder: TrackRecordBuilder, in root: inout ITunesDBRecord) -> String? {
        guard let section = root.children.firstIndex(where: { $0.isSection(.tracks) }),
              let index = trackList(in: root)?.children.firstIndex(where: {
                  $0.uint64(at: databaseIDOffset) == databaseID
              }) else { return nil }
        var mhit = root.children[section].children[0].children[index]
        let previous = (location: mhit.string(ofType: ITunesStringField.location.rawValue),
                        albumID: AlbumListPruner.albumID(of: mhit))
        let kept = mhit.children.filter { !($0.tag == "mhod" && replacedStrings.contains($0.recordType)) }
        mhit.children = TrackRecordBuilder.stringRecords(for: draft) + kept
        mhit.set(UInt32(mhit.children.count), at: 0x0C)
        mhit.set(albumID, at: albumIDOffset)
        builder.apply(draft, to: &mhit, includingArtwork: !keepingArtwork)
        root.children[section].children[0].children[index] = mhit
        AlbumListPruner.prune([previous.albumID], in: &root)
        return previous.location
    }

    private static func trackList(in root: ITunesDBRecord) -> ITunesDBRecord? {
        root.children.first { $0.isSection(.tracks) }?.children.first
    }
}
