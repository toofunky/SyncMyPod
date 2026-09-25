import Foundation

/// Removes tracks from an iTunesDB tree: their `mhit`s, every playlist entry for them,
/// and album-list entries that no remaining track uses.
nonisolated enum ITunesDBTrackRemover {
    private static let databaseIDOffset = 0x70
    private static let albumIDOffset = 0x120
    private static let playlistSections: [ITunesDBSectionType] = [.playlists, .podcasts, .smartPlaylists]

    /// Returns the iPod location strings of the removed tracks' audio files.
    static func remove(_ databaseIDs: Set<UInt64>, from root: inout ITunesDBRecord) -> [String] {
        guard let trackSection = root.children.firstIndex(where: { $0.isSection(.tracks) }),
              !root.children[trackSection].children.isEmpty else { return [] }
        let tracks = root.children[trackSection].children[0].children
        let removed = tracks.filter { databaseIDs.contains($0.uint64(at: databaseIDOffset)) }
        guard !removed.isEmpty else { return [] }
        let kept = tracks.filter { !databaseIDs.contains($0.uint64(at: databaseIDOffset)) }
        root.children[trackSection].children[0].children = kept
        let removedTrackIDs = Set(removed.map { $0.uint32(at: 0x10) })
        for index in root.children.indices where playlistSections.contains(where: root.children[index].isSection) {
            modifyPlaylists(in: &root.children[index]) { removeItems(from: &$0, trackIDs: removedTrackIDs) }
        }
        let orphanedAlbums = Set(removed.map(albumID)).subtracting(kept.map(albumID))
        removeAlbums(orphanedAlbums, from: &root)
        return removed.compactMap { $0.string(ofType: ITunesStringField.location.rawValue) }
    }

    private static func albumID(_ mhit: ITunesDBRecord) -> UInt32 {
        mhit.uint32(at: albumIDOffset)
    }

    private static func modifyPlaylists(in section: inout ITunesDBRecord, _ change: (inout ITunesDBRecord) -> Void) {
        guard !section.children.isEmpty else { return }
        for index in section.children[0].children.indices {
            change(&section.children[0].children[index])
        }
    }

    private static func removeItems(from playlist: inout ITunesDBRecord, trackIDs: Set<UInt32>) {
        let before = playlist.children.count
        playlist.children.removeAll { $0.tag == "mhip" && trackIDs.contains($0.uint32(at: 0x18)) }
        let removedCount = UInt32(before - playlist.children.count)
        guard removedCount > 0 else { return }
        playlist.set(playlist.uint32(at: 0x10) - removedCount, at: 0x10)
    }

    private static func removeAlbums(_ albumIDs: Set<UInt32>, from root: inout ITunesDBRecord) {
        let unused = albumIDs.subtracting([0])
        guard !unused.isEmpty,
              let section = root.children.firstIndex(where: { $0.isSection(.albums) }),
              !root.children[section].children.isEmpty else { return }
        root.children[section].children[0].children.removeAll { unused.contains($0.uint32(at: 0x10)) }
    }
}
