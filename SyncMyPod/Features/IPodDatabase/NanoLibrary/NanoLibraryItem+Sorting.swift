import Foundation

/// iTunes fills every sort column on the nano, generating values without a leading article or leading punctuation
/// where the file has no sort tag.
nonisolated extension NanoLibraryItem {
    var sortTitle: String? { sortValue(.sortTitle, fallback: .title) }
    var sortArtist: String? { sortValue(.sortArtist, fallback: .artist) }
    var sortAlbum: String? { sortValue(.sortAlbum, fallback: .album) }
    var sortAlbumArtist: String? { sortValue(.sortAlbumArtist, fallback: .albumArtist) }
    var sortComposer: String? { sortValue(.sortComposer, fallback: .composer) }

    /// How the album artist sorts in the Artists menu, falling back to the track artist.
    var albumArtistSortKey: String? { string(.albumArtist) == nil ? sortArtist : sortAlbumArtist }

    private func sortValue(_ field: ITunesStringField, fallback: ITunesStringField) -> String? {
        guard let value = string(field) ?? string(fallback).map(Self.withoutLeadingPunctuation)?.sortName else {
            return nil
        }
        return Self.withoutLeadingPunctuation(value)
    }

    /// "“&” (Ampersand)" → "Ampersand)"; a value with no letters or digits is kept as is.
    private static func withoutLeadingPunctuation(_ value: String) -> String {
        let trimmed = value.drop { !$0.isLetter && !$0.isNumber }
        return trimmed.isEmpty ? value : String(trimmed)
    }
}
