import AVFoundation

/// Sort tags AVFoundation reads but doesn't name. `TSO2` and `TSOC` are iTunes' own ID3 frames.
nonisolated extension AVMetadataIdentifier {
    static let iTunesSortName = sortIdentifier("sonm", .iTunes)
    static let iTunesSortArtist = sortIdentifier("soar", .iTunes)
    static let iTunesSortAlbumArtist = sortIdentifier("soaa", .iTunes)
    static let iTunesSortAlbum = sortIdentifier("soal", .iTunes)
    static let iTunesSortComposer = sortIdentifier("soco", .iTunes)
    static let id3SortAlbumArtist = sortIdentifier("TSO2", .id3)
    static let id3SortComposer = sortIdentifier("TSOC", .id3)

    private static func sortIdentifier(_ key: String, _ keySpace: AVMetadataKeySpace) -> AVMetadataIdentifier {
        AVMetadataItem.identifier(forKey: key as NSString, keySpace: keySpace)
            ?? AVMetadataIdentifier(rawValue: "\(keySpace.rawValue)/\(key)")
    }
}
