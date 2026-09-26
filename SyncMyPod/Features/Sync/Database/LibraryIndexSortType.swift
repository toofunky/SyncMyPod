import Foundation

/// Sort orders of the master playlist's type-52 index `mhod`s that the 5G firmware browses with.
nonisolated enum LibraryIndexSortType: UInt32, CaseIterable, Sendable {
    case title = 0x03
    case artist = 0x05
    case album = 0x04
    case genre = 0x07
    case composer = 0x12

    /// Sort components, most significant first. The first one also drives the jump table letter.
    func sortKey(for track: ITunesTrack) -> [String] {
        let title = value(track, .sortTitle, .title)
        let albumTail = [value(track, .sortAlbum, .album), padded(track.discNumber),
                         padded(track.trackNumber), title]
        switch self {
        case .title: return [title]
        case .album: return albumTail
        case .artist: return [value(track, .sortArtist, .artist)] + albumTail
        case .genre: return [track.genre, value(track, .sortArtist, .artist)] + albumTail
        case .composer: return [value(track, .sortComposer, .composer), title]
        }
    }

    private func value(_ track: ITunesTrack, _ sortField: ITunesStringField,
                       _ field: ITunesStringField) -> String {
        track.strings[sortField] ?? track.strings[field] ?? ""
    }

    private func padded(_ number: Int) -> String {
        String(repeating: "0", count: max(0, 6 - String(number).count)) + String(number)
    }
}
