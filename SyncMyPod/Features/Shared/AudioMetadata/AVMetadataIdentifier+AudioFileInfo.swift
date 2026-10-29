import AVFoundation

/// Core Audio's info dictionary, which AVFoundation reads as `caaf/info-` + the key, with spaces
/// percent-encoded. It holds WAV `LIST/INFO` tags and AIFF's own `NAME` and `AUTH` chunks.
nonisolated extension AVMetadataIdentifier {
    static let audioFileTitle = audioFileInfo("title")
    static let audioFileArtist = audioFileInfo("artist")
    static let audioFileAlbum = audioFileInfo("album")
    static let audioFileComposer = audioFileInfo("composer")
    static let audioFileGenre = audioFileInfo("genre")
    static let audioFileYear = audioFileInfo("year")
    static let audioFileTrackNumber = audioFileInfo("track%20number")

    private static func audioFileInfo(_ key: String) -> AVMetadataIdentifier {
        AVMetadataIdentifier(rawValue: "caaf/info-\(key)")
    }
}
