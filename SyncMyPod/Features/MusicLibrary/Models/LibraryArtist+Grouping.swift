import Foundation

extension LibraryArtist {
    /// Alphabetical, ignoring a leading "A", "An" or "The" unless the songs have sort tags.
    static func artists(from tracks: [LibraryTrack]) -> [LibraryArtist] {
        Dictionary(grouping: tracks, by: \.syncArtist)
            .map { name, tracks in
                LibraryArtist(id: name, sortName: tracks[0].syncArtistSortName,
                              albumCount: Set(tracks.map(\.syncAlbum)).count)
            }
            .sorted { $0.sortName.localizedStandardCompare($1.sortName) == .orderedAscending }
    }
}
