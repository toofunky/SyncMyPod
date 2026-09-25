import Foundation
import SwiftData

@Model
nonisolated final class LibraryTrack {
    /// Bumped when scanning starts reading something new, so older rows get re-read.
    static let currentScanVersion = 1

    @Attribute(.unique) var filePath: String
    var fileSize = 0
    var modificationDate = Date.distantPast
    var title = ""
    var artist = ""
    var album = ""
    var albumArtist = ""
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
    var scanVersion = 0

    init(filePath: String) {
        self.filePath = filePath
    }

    func matches(_ file: ScannedAudioFile) -> Bool {
        scanVersion == Self.currentScanVersion && fileSize == file.fileSize
            && modificationDate == file.modificationDate
    }

    func update(file: ScannedAudioFile, metadata: AudioFileMetadata) {
        fileSize = file.fileSize
        modificationDate = file.modificationDate
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
        genre = tags.genre ?? ""
        year = tags.year ?? 0
        trackNumber = tags.track.number
        trackCount = tags.track.count
        discNumber = tags.disc.number
        discCount = tags.disc.count
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
