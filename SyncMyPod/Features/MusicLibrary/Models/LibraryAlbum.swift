import Foundation

/// The songs that share an album artist and album name, as the iPod groups them.
nonisolated struct LibraryAlbum: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let artist: String
    let titleSortName: String
    let artistSortName: String
    let genre: String
    let genreSortName: String
    let year: Int
    let trackCount: Int
    let artworkPath: String?
    let artworkFingerprint: String?

    var yearText: String { year > 0 ? String(year) : "" }
}

#if DEBUG
extension LibraryAlbum {
    static let preview = LibraryAlbum(id: "OutKast\u{1F}Speakerboxxx/The Love Below",
                                      title: "Speakerboxxx/The Love Below", artist: "OutKast",
                                      titleSortName: "Speakerboxxx/The Love Below", artistSortName: "OutKast",
                                      genre: "Hip-Hop/Rap", genreSortName: "Hip-Hop/Rap",
                                      year: 2003, trackCount: 2, artworkPath: nil, artworkFingerprint: nil)
}
#endif
