import AVFoundation

/// FLAC's Vorbis comments, which AVFoundation reads as `vorb/` + the upper-cased field name, with spaces
/// percent-encoded, but doesn't name.
nonisolated extension AVMetadataIdentifier {
    static let vorbisTitle = vorbis("TITLE")
    static let vorbisArtist = vorbis("ARTIST")
    static let vorbisAlbum = vorbis("ALBUM")
    static let vorbisAlbumArtist = vorbis("ALBUMARTIST")
    static let vorbisAlbumArtistSpaced = vorbis("ALBUM%20ARTIST")
    static let vorbisComposer = vorbis("COMPOSER")
    static let vorbisGenre = vorbis("GENRE")
    static let vorbisDate = vorbis("DATE")
    static let vorbisYear = vorbis("YEAR")
    static let vorbisTrackNumber = vorbis("TRACKNUMBER")
    static let vorbisTrackTotal = vorbis("TRACKTOTAL")
    static let vorbisTotalTracks = vorbis("TOTALTRACKS")
    static let vorbisDiscNumber = vorbis("DISCNUMBER")
    static let vorbisDiscTotal = vorbis("DISCTOTAL")
    static let vorbisTotalDiscs = vorbis("TOTALDISCS")
    static let vorbisSortTitle = vorbis("TITLESORT")
    static let vorbisSortArtist = vorbis("ARTISTSORT")
    static let vorbisSortAlbumArtist = vorbis("ALBUMARTISTSORT")
    static let vorbisSortAlbum = vorbis("ALBUMSORT")
    static let vorbisSortComposer = vorbis("COMPOSERSORT")
    static let vorbisLyrics = vorbis("LYRICS")
    static let vorbisUnsyncedLyrics = vorbis("UNSYNCEDLYRICS")
    /// AVFoundation hands back just the image bytes of FLAC's `PICTURE` block.
    static let vorbisPicture = vorbis("METADATA_BLOCK_PICTURE")

    private static func vorbis(_ field: String) -> AVMetadataIdentifier {
        AVMetadataIdentifier(rawValue: "vorb/\(field)")
    }
}
