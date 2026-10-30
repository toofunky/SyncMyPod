import Foundation
import SwiftData
import Testing
@testable import SyncMyPod

@MainActor
struct SyncLibrarySourcesTests {
    private let container = ModelContainer.makeInMemory()

    private func temporaryFolder() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "SyncLibrarySourcesTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        for name in ["Podcasts", "Books"] {
            try FileManager.default.createDirectory(at: url.appending(path: name), withIntermediateDirectories: true)
        }
        return url
    }

    private func podcast(downloadedAt path: String?) -> Podcast {
        let podcast = Podcast(feedURL: "https://example.com/show", title: "Show")
        container.mainContext.insert(podcast)
        let episode = PodcastEpisode(guid: "1", title: "Episode", enclosureURL: "https://example.com/1.mp3")
        episode.downloadedFilePath = path
        podcast.episodes.append(episode)
        return podcast
    }

    private func book(fileAt path: String) -> Audiobook {
        let book = Audiobook(folderPath: (path as NSString).deletingLastPathComponent, title: "Book")
        container.mainContext.insert(book)
        book.files = [AudiobookFile(filePath: path)]
        return book
    }

    @Test func removedDownloadsComeFromBothFolders() throws {
        let root = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let podcasts = root.appending(path: "Podcasts").path(percentEncoded: false)
        let books = root.appending(path: "Books").path(percentEncoded: false)
        let kept = podcasts + "/kept.mp3"
        try Data().write(to: URL(filePath: kept))
        let sources = SyncLibrarySources(podcasts: [podcast(downloadedAt: kept)], podcastFolderPath: podcasts,
                                         audiobookFolderPath: books)
        let removed = sources.removedDownloads(among: [kept, podcasts + "/gone.mp3", books + "/gone.m4a",
                                                       "/Music/song.m4a"])
        #expect(removed == [podcasts + "/gone.mp3", books + "/gone.m4a"])
    }

    @Test func listedBookFilesAreKeptEvenWhenNotOnDisk() throws {
        let root = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let books = root.appending(path: "Books").path(percentEncoded: false)
        let listed = books + "/Book/01.m4a"
        let sources = SyncLibrarySources(audiobooks: [book(fileAt: listed)], audiobookFolderPath: books)
        #expect(sources.removedDownloads(among: [listed]).isEmpty)
    }

    @Test func episodesThatAreNotDownloadedLeaveNothingToSync() {
        #expect(SyncLibrarySources(podcasts: [podcast(downloadedAt: nil)]).isEmpty)
        #expect(!SyncLibrarySources(podcasts: [podcast(downloadedAt: "/Podcasts/1.mp3")]).isEmpty)
    }

    @Test func songsAreNeverMissingWithoutAMusicFolder() {
        #expect(SyncLibrarySources().missingSongs(among: ["/Music/song.m4a"]).isEmpty)
    }
}
