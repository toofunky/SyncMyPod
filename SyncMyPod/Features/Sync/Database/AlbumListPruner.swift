import Foundation

/// Removes album-list entries that no track refers to any more.
nonisolated enum AlbumListPruner {
    private static let albumIDOffset = 0x120

    static func albumID(of mhit: ITunesDBRecord) -> UInt32 {
        mhit.uint32(at: albumIDOffset)
    }

    /// Removes those of `candidates` that no remaining track uses.
    static func prune(_ candidates: Set<UInt32>, in root: inout ITunesDBRecord) {
        let tracks = root.children.first { $0.isSection(.tracks) }?.children.first?.children ?? []
        let unused = candidates.subtracting(tracks.map(albumID)).subtracting([0])
        guard !unused.isEmpty,
              let section = root.children.firstIndex(where: { $0.isSection(.albums) }),
              !root.children[section].children.isEmpty else { return }
        root.children[section].children[0].children.removeAll { unused.contains($0.uint32(at: 0x10)) }
    }
}
