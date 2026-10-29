import Foundation

/// An album (`mhia`) or album artist (`mhii`) entry: the persistent ID the SQLite tables use, keyed by the
/// 32-bit ID tracks link to.
nonisolated struct NanoLibraryGroup: Equatable, Sendable {
    static let albumNameType: UInt32 = 200
    static let albumArtistType: UInt32 = 201
    static let artistNameType: UInt32 = 300

    let id: UInt32
    let pid: UInt64
    let name: String?
    let artistName: String?

    init(id: UInt32, pid: UInt64, name: String?, artistName: String?) {
        self.id = id
        self.pid = pid
        self.name = name
        self.artistName = artistName
    }

    init(record: ITunesDBRecord) {
        let nameType = record.tag == "mhii" ? Self.artistNameType : Self.albumNameType
        self.init(id: record.uint32(at: 0x10), pid: record.uint64(at: 0x14), name: record.string(ofType: nameType),
                  artistName: record.string(ofType: Self.albumArtistType))
    }
}
