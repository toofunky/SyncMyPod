import Foundation

/// An `mhyp` playlist, including the hidden master and the nano's built-in media-kind lists.
nonisolated struct NanoLibraryPlaylist: Equatable, Sendable {
    let pid: UInt64
    let name: String
    let isMaster: Bool
    /// Non-zero for the built-in Music, Movies, TV Shows, Audiobooks and similar lists.
    let distinguishedKind: Int
    let dateCreated: UInt32
    let itemPIDs: [UInt64]

    /// The built-in Music list shows songs; the other built-in lists hold only video, books or rentals.
    private static let musicKind = 4

    var isHidden: Bool { isMaster || distinguishedKind != 0 }
    var holdsMusic: Bool { distinguishedKind == 0 || distinguishedKind == Self.musicKind }

    init(pid: UInt64, name: String, isMaster: Bool, distinguishedKind: Int, dateCreated: UInt32,
         itemPIDs: [UInt64]) {
        self.pid = pid
        self.name = name
        self.isMaster = isMaster
        self.distinguishedKind = distinguishedKind
        self.dateCreated = dateCreated
        self.itemPIDs = itemPIDs
    }

    /// `pidsByTrackID` maps the 32-bit track IDs `mhip` entries use to database IDs.
    init(mhyp: ITunesDBRecord, pidsByTrackID: [UInt32: UInt64]) {
        let entries = mhyp.children.filter { $0.tag == "mhip" }
        self.init(pid: mhyp.uint64(at: 0x1C), name: mhyp.string(ofType: ITunesStringField.title.rawValue) ?? "",
                  isMaster: mhyp.isMasterPlaylist, distinguishedKind: Int(mhyp.uint8(at: 0x52)),
                  dateCreated: mhyp.uint32(at: 0x18),
                  itemPIDs: entries.compactMap { pidsByTrackID[$0.uint32(at: 0x18)] })
    }
}
