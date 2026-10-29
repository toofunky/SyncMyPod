import Foundation
import SwiftData
import Testing
@testable import SyncMyPod

@MainActor
struct PodcastIPodSyncPlanTests {
    private let container = ModelContainer.makeInMemory()
    private static let downloaded = Date(timeIntervalSince1970: 1_800_000_000)

    private func podcast(_ title: String, files: [String]) -> Podcast {
        let podcast = Podcast(feedURL: "https://example.com/\(title)", title: title)
        container.mainContext.insert(podcast)
        for (index, file) in files.enumerated() {
            let episode = PodcastEpisode(guid: file, title: file, enclosureURL: "https://example.com/\(file)")
            episode.publishedAt = Date(timeIntervalSince1970: Double(index) * 86_400)
            episode.downloadedFilePath = "/Podcasts/\(title)/\(file)"
            episode.downloadedAt = Self.downloaded
            episode.byteCount = 2_048
            podcast.episodes.append(episode)
        }
        return podcast
    }

    private func plan(_ podcasts: [Podcast], selection: SyncSelection) async -> SyncPlan {
        let library = SyncLibrarySnapshot(tracks: [], playlists: [], podcasts: podcasts, forIPod: true,
                                          preservingAlbumArtist: false)
        let empty = ITunesDatabase(version: 0x19, databaseID: 1, tracks: [], playlists: [])
        return await SyncPlanInput(library: library, selection: selection, onDevice: empty,
                                   manifest: LoadedSyncManifest()).plan()
    }

    @Test func iPodEpisodesCarryWhatTheManifestRecordsAndPlayersDont() throws {
        let show = podcast("Show", files: ["One.mp3"])
        let episode = try #require(show.episodes.first)
        let forIPod = try #require(episode.syncRequest(show: "Show", author: "", forIPod: true))
        #expect(forIPod.source == SyncSource(fileSize: 2_048, modificationDate: Self.downloaded, artworkFingerprint: nil))
        #expect(forIPod.kind == .podcast && forIPod.tags.releaseDate == episode.publishedAt)
        #expect(try #require(episode.syncRequest(show: "Show", author: "")).source == nil)
    }

    @Test func iPodsLeaveOutEpisodesTheyCantPlay() {
        let show = podcast("Show", files: ["One.ogg", "Two.mp3"])
        #expect(show.syncSnapshot(forIPod: true)?.episodes.map(\.tags.title) == ["Two.mp3"])
        #expect(show.syncSnapshot()?.episodes.count == 2)
    }

    @Test func chosenEpisodesAreAddedWithThePodcastsList() async throws {
        let chosen = podcast("Chosen", files: ["A.mp3", "B.mp3"])
        let other = podcast("Other", files: ["C.mp3"])
        let plan = await plan([chosen, other], selection: SyncSelection(podcastScope: .selected, podcasts: [chosen.syncKey]))
        #expect(plan.requests.map(\.tags.title) == ["A.mp3", "B.mp3"])
        let list = try #require(plan.playlists.first { $0.isPodcasts })
        #expect(list.id == SyncPlaylistRequest.podcastsID && list.tracks.map(\.tags.title) == ["A.mp3", "B.mp3"])
    }

    @Test func noPodcastsListWithoutEpisodes() async {
        let plan = await plan([podcast("Show", files: ["A.mp3"])], selection: SyncSelection(podcastScope: .selected))
        #expect(plan.playlists.isEmpty && plan.requests.isEmpty)
    }
}
