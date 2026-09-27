import Foundation
import SwiftData

@Model
nonisolated final class LibraryTrack {
    /// Bumped when scanning starts reading something new, so older rows get re-read.
    /// 2: the `codec` → `codecRawValue` rename left older rows `NULL`, so they must be re-read.
    /// 3: reads the composer.
    /// 4: reads the sort tags.
    static let currentScanVersion = 4

    @Attribute(.unique) var filePath: String
    /// Optional because rows from before a rescan can hold `NULL`; those read as AAC.
    @Attribute(originalName: "codec") var codecRawValue: String?
    var fileSize = 0
    var modificationDate = Date.distantPast
    var title = ""
    var artist = ""
    var album = ""
    var albumArtist = ""
    /// Optional because rows scanned before composers were read hold `NULL`.
    var composerTag: String?
    var genre = ""
    var trackNumber = 0
    var trackCount = 0
    var discNumber = 0
    var discCount = 0
    var year = 0
    var duration: TimeInterval = 0
    var bitrate = 0
    var sampleRate = 0
    var dateAdded = Date.now
    var artworkFingerprint: String?
    /// Optional, like `composerTag`, because rows scanned before sort tags were read hold `NULL`.
    var sortTitleTag: String?
    var sortArtistTag: String?
    var sortAlbumArtistTag: String?
    var sortAlbumTag: String?
    var sortComposerTag: String?
    var scanVersion = 0

    init(filePath: String) {
        self.filePath = filePath
    }

    var composer: String { composerTag ?? "" }

    var codec: AudioCodec {
        get { codecRawValue.flatMap(AudioCodec.init(rawValue:)) ?? .aac }
        set { codecRawValue = newValue.rawValue }
    }

    func matches(_ file: ScannedAudioFile) -> Bool {
        scanVersion == Self.currentScanVersion && fileSize == file.fileSize
            && modificationDate == file.modificationDate
    }

    func update(file: ScannedAudioFile, metadata: AudioFileMetadata) {
        fileSize = file.fileSize
        modificationDate = file.modificationDate
        codec = metadata.codec
        duration = metadata.duration
        bitrate = metadata.bitrate
        sampleRate = metadata.sampleRate
        artworkFingerprint = metadata.artworkFingerprint
        scanVersion = Self.currentScanVersion
        apply(metadata.tags, fallbackTitle: file.url.deletingPathExtension().lastPathComponent)
    }

    private func apply(_ tags: AudioTags, fallbackTitle: String) {
        title = tags.title ?? fallbackTitle
        artist = tags.artist ?? ""
        album = tags.album ?? ""
        albumArtist = tags.albumArtist ?? ""
        composerTag = tags.composer
        genre = tags.genre ?? ""
        year = tags.year ?? 0
        trackNumber = tags.track.number
        trackCount = tags.track.count
        discNumber = tags.disc.number
        discCount = tags.disc.count
        applySortTags(tags)
    }

    private func applySortTags(_ tags: AudioTags) {
        sortTitleTag = tags.sortTitle
        sortArtistTag = tags.sortArtist
        sortAlbumArtistTag = tags.sortAlbumArtist
        sortAlbumTag = tags.sortAlbum
        sortComposerTag = tags.sortComposer
    }
}

#if DEBUG
extension LibraryTrack {
    static func preview(_ title: String, artist: String, album: String,
                        duration: TimeInterval) -> LibraryTrack {
        let track = LibraryTrack(filePath: "/Music/\(artist)/\(album)/\(title).m4a")
        track.title = title
        track.artist = artist
        track.album = album
        track.duration = duration
        track.bitrate = 256
        track.sampleRate = 44_100
        return track
    }

    static let previewTracks: [LibraryTrack] = [
        .preview("Hey Ya!", artist: "OutKast", album: "Speakerboxxx/The Love Below", duration: 235),
        .preview("Mr. Brightside", artist: "The Killers", album: "Hot Fuss", duration: 222),
        .preview("Float On", artist: "Modest Mouse", album: "Good News", duration: 208),
    ]
}
#endif
