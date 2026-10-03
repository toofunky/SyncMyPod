import Foundation
@testable import SyncMyPod

/// A throwaway volume set up as an audio player, with a separate library folder, removed when the test ends.
final class TemporaryPlayerVolume {
    let root = FileManager.default.temporaryDirectory
        .appending(path: "SyncMyPodPlayerTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    var volumeURL: URL { root.appending(path: "Volume", directoryHint: .isDirectory) }
    var libraryURL: URL { root.appending(path: "Library", directoryHint: .isDirectory) }

    init(config: AudioPlayerConfig) throws {
        try FileManager.default.createDirectory(at: volumeURL, withIntermediateDirectories: true)
        try AudioPlayerControlFiles(volumeURL: volumeURL).save(config)
    }

    deinit {
        try? FileManager.default.removeItem(at: root)
    }

    var device: AudioPlayerDevice {
        get throws {
            guard let device = AudioPlayerDevice(scanningVolumeAt: volumeURL) else { throw CocoaError(.fileNoSuchFile) }
            return device
        }
    }

    func request(_ title: String, album: String = "Album", artist: String = "Artist", file: String? = nil,
                 track: Int = 1, disc: Int = 0, discCount: Int = 0, bytes: Int = 512,
                 modified: Date = Date(timeIntervalSince1970: 1_000)) throws -> IPodSyncRequest {
        let source = libraryURL.appending(path: file ?? "\(title).m4a")
        try FileManager.default.createDirectory(at: source.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(repeating: UInt8(title.count % 256), count: bytes).write(to: source)
        let draft = ITunesTrackDraft(title: title, artist: artist, album: album, fileSize: bytes, trackNumber: track,
                                     discNumber: disc, discCount: discCount)
        return IPodSyncRequest(sourceURL: source, draft: draft,
                               source: SyncSource(fileSize: bytes, modificationDate: modified, artworkFingerprint: nil))
    }

    func fileExists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: volumeURL.appending(path: path).path(percentEncoded: false))
    }

    func contents(of path: String) throws -> String {
        try String(contentsOf: volumeURL.appending(path: path), encoding: .utf8)
    }
}
