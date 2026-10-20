import Foundation
import SwiftData

/// One audio file of an audiobook, such as a chapter or a part.
@Model
nonisolated final class AudiobookFile {
    /// Bumped when scanning starts reading something new, so older rows get re-read.
    static let currentScanVersion = 1

    @Attribute(.unique) var filePath: String
    var title = ""
    var trackNumber = 0
    var discNumber = 0
    var duration: TimeInterval = 0
    var codecRawValue: String?
    var fileSize = 0
    var modificationDate = Date.distantPast
    var bitrate = 0
    var sampleRate = 0
    var scanVersion = 0
    var book: Audiobook?

    init(filePath: String) {
        self.filePath = filePath
    }

    var fileURL: URL { URL(filePath: filePath) }

    var fileName: String { fileURL.lastPathComponent }

    var codec: AudioCodec? { codecRawValue.flatMap(AudioCodec.init(rawValue:)) }

    func matches(_ file: ScannedAudioFile) -> Bool {
        scanVersion == Self.currentScanVersion && fileSize == file.fileSize
            && modificationDate == file.modificationDate
    }

    func update(file: ScannedAudioFile, metadata: AudioFileMetadata) {
        fileSize = file.fileSize
        modificationDate = file.modificationDate
        codecRawValue = metadata.codec.rawValue
        duration = metadata.duration
        bitrate = metadata.bitrate
        sampleRate = metadata.sampleRate
        title = metadata.tags.title ?? file.url.deletingPathExtension().lastPathComponent
        trackNumber = metadata.tags.track.number
        discNumber = metadata.tags.disc.number
        scanVersion = Self.currentScanVersion
    }

    static func playsBefore(_ lhs: AudiobookFile, _ rhs: AudiobookFile) -> Bool {
        if lhs.discNumber != rhs.discNumber { return lhs.discNumber < rhs.discNumber }
        if lhs.trackNumber != rhs.trackNumber { return lhs.trackNumber < rhs.trackNumber }
        return lhs.fileName.localizedStandardCompare(rhs.fileName) == .orderedAscending
    }
}

#if DEBUG
extension AudiobookFile {
    static var previewFiles: [AudiobookFile] {
        ["Letters 1–4", "Chapters 1–5", "Chapters 6–10"].enumerated().map { index, title in
            let file = AudiobookFile(filePath: "/Users/me/Audiobooks/Mary Shelley/Frankenstein/0\(index + 1).m4a")
            file.title = title
            file.trackNumber = index + 1
            file.duration = 2_400 + Double(index) * 300
            file.fileSize = 38_000_000 + index * 4_000_000
            return file
        }
    }
}
#endif
