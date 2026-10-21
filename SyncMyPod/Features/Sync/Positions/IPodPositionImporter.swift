import Foundation
import SwiftData

/// Brings listening positions back from an iPod: each episode or book the iPod was listened to since it was last
/// read takes the iPod's position, if that's further along than SyncMyPod's.
struct IPodPositionImporter {
    let deviceID: String
    let context: ModelContext

    func importPositions(from tracks: [ITunesTrack], manifest: SyncManifest, podcasts: [Podcast],
                         audiobooks: [Audiobook]) {
        let tracksByID = Dictionary(tracks.map { ($0.databaseID, $0) }, uniquingKeysWith: { first, _ in first })
        let onDevice = manifest.entries.compactMapValues { entry in tracksByID[entry.databaseID] }
        let seen = seenBookmarks()
        let changed = onDevice.filter { path, track in Self.hasChanged(track, since: seen[path]) }
        for episode in podcasts.flatMap(\.episodes) {
            guard let path = episode.downloadedFilePath, let track = changed[path] else { continue }
            apply(track.bookmark, to: episode)
        }
        for book in audiobooks { apply(changed, to: book) }
        record(onDevice, seen: seen)
        if context.hasChanges { try? context.save() }
    }

    /// The tracks with positions the iPod has saved since its last sync, which it keeps in its Play Counts file
    /// until then, merged as a sync merges them. Unchanged when the entries don't line up with the tracks.
    static func withPendingBookmarks(_ tracks: [ITunesTrack], playCounts: [PlayCountEntry]?) -> [ITunesTrack] {
        guard let playCounts, playCounts.count == tracks.count else { return tracks }
        return zip(tracks, playCounts).map { track, entry in
            var track = track
            if entry.bookmark > 0 { track.bookmark = TimeInterval(entry.bookmark) / 1000 }
            return track
        }
    }

    /// Never-seen tracks count as changed only once they've been listened to, so a fresh copy at 0 changes nothing.
    private static func hasChanged(_ track: ITunesTrack, since seen: DeviceBookmark?) -> Bool {
        guard let seen, seen.databaseID == track.databaseID else { return track.bookmark > 0 }
        return seen.position != track.bookmark
    }

    private func apply(_ position: TimeInterval, to episode: PodcastEpisode) {
        guard let merged = SpokenPositionMerge.episode(app: episode.playbackPosition, device: position,
                                                       duration: episode.duration) else { return }
        episode.playbackPosition = merged
    }

    /// The furthest file in the book the iPod changed stands for where listening on the iPod got to.
    private func apply(_ changed: [String: ITunesTrack], to book: Audiobook) {
        let files = book.sortedFiles
        guard let index = files.lastIndex(where: { changed[$0.filePath] != nil }),
              let track = changed[files[index].filePath] else { return }
        let appIndex = book.currentFilePath.flatMap { path in files.firstIndex { $0.filePath == path } }
        guard let merged = SpokenPositionMerge.book(durations: files.map(\.duration),
                                                    app: (appIndex, book.playbackPosition),
                                                    device: (index, track.bookmark)) else { return }
        book.currentFilePath = merged.index.map { files[$0].filePath }
        book.playbackPosition = merged.position
    }

    private func seenBookmarks() -> [String: DeviceBookmark] {
        let deviceID = deviceID
        let descriptor = FetchDescriptor<DeviceBookmark>(predicate: #Predicate { $0.deviceID == deviceID })
        let bookmarks = (try? context.fetch(descriptor)) ?? []
        return Dictionary(bookmarks.map { ($0.sourcePath, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// Only episodes and book files are kept, since songs don't resume.
    private func record(_ onDevice: [String: ITunesTrack], seen: [String: DeviceBookmark]) {
        for (path, track) in onDevice where track.bookmark > 0 || seen[path] != nil {
            if let bookmark = seen[path] {
                if bookmark.databaseID != track.databaseID { bookmark.databaseID = track.databaseID }
                if bookmark.position != track.bookmark { bookmark.position = track.bookmark }
            } else {
                context.insert(DeviceBookmark(deviceID: deviceID, sourcePath: path, databaseID: track.databaseID,
                                              position: track.bookmark))
            }
        }
    }
}
