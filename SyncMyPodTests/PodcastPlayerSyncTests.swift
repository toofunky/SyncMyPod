import Foundation
import SwiftData
import Testing
@testable import SyncMyPod

@MainActor
struct PodcastPlayerSyncTests {
    private let container = ModelContainer.makeInMemory()
    private let config = AudioPlayerConfig(name: "Player", rootPath: "", musicFolder: "Music",
                                           playlistFolder: "Playlists")
    private static let day: TimeInterval = 86_400

    /// Episodes are named and dated as downloads are, in the order given; only `downloaded` ones have files.
    private func podcast(_ title: String, episodes: [String], downloaded: Set<String>? = nil) -> Podcast {
        let podcast = Podcast(feedURL: "https://example.com/\(title)", title: title)
        container.mainContext.insert(podcast)
        for (index, name) in episodes.enumerated() {
            let episode = PodcastEpisode(guid: name, title: name, enclosureURL: "https://example.com/\(name).mp3")
            episode.publishedAt = Date(timeIntervalSince1970: Double(index) * Self.day)
            if downloaded?.contains(name) ?? true {
                episode.downloadedFilePath = "/Podcasts/\(title)/\(name).mp3"
                episode.byteCount = 1_000
            }
            podcast.episodes.append(episode)
        }
        return podcast
    }

    private func plan(_ podcasts: [Podcast], selection: SyncSelection, config: AudioPlayerConfig? = nil,
                      contents: PlayerDeviceContents = PlayerDeviceContents(),
                      missing: Set<String> = []) async -> PlayerSyncPlan {
        let library = SyncLibrarySnapshot(tracks: [], playlists: [], podcasts: podcasts, preservingAlbumArtist: false)
        return await PlayerPlanInput(library: library, selection: selection, contents: contents,
                                     config: config ?? self.config, missingSources: missing,
                                     sidecars: LibrarySidecars()).plan()
    }

    @Test func snapshotsHoldOnlyDownloadedEpisodesOldestFirst() throws {
        let show = podcast("Show", episodes: ["First", "Second", "Third"], downloaded: ["Third", "First"])
        let snapshot = try #require(show.syncSnapshot())
        #expect(snapshot.episodes.map(\.draft.title) == ["First", "Third"])
        #expect(snapshot.episodes.allSatisfy { $0.isPodcast && $0.source == nil && $0.draft.album == "Show" })
        #expect(podcast("Empty", episodes: ["Only"], downloaded: []).syncSnapshot() == nil)
    }

    @Test func episodesGoInThePodcastFolderUnderTheirShow() async {
        let plan = await plan([podcast("Show", episodes: ["Episode"])], selection: SyncSelection(mode: .allSongs))
        #expect(plan.copies.map(\.destination) == ["Podcasts/Show/Episode.mp3"])
    }

    @Test func aBlankPodcastFolderUsesTheRoot() async {
        var rooted = config
        rooted.podcastFolder = ""
        let plan = await plan([podcast("Show", episodes: ["Episode"])], selection: SyncSelection(mode: .allSongs),
                              config: rooted)
        #expect(plan.copies.map(\.destination) == ["Show/Episode.mp3"])
    }

    @Test func customSyncCopiesChosenPodcastsAndRemovesOthers() async throws {
        let chosen = podcast("Chosen", episodes: ["A"])
        let other = podcast("Other", episodes: ["B"])
        let synced = PlayerManifestEntry(path: "Podcasts/Other/B.mp3", source: nil)
        let contents = PlayerDeviceContents(manifest: PlayerSyncManifest(entries: ["/Podcasts/Other/B.mp3": synced]),
                                            presentSizes: [synced.path: 1_000])
        let plan = await plan([chosen, other], selection: SyncSelection(mode: .custom, podcasts: [chosen.syncKey]),
                              contents: contents)
        #expect(plan.copies.map(\.destination) == ["Podcasts/Chosen/A.mp3"])
        #expect(plan.removals.map(\.path) == ["Podcasts/Other/B.mp3"])
    }

    @Test func episodesOnThePlayerAreNeverCopiedAgain() async {
        let show = podcast("Show", episodes: ["Episode"])
        let entry = PlayerManifestEntry(path: "Podcasts/Show/Episode.mp3", source: nil)
        let contents = PlayerDeviceContents(manifest: PlayerSyncManifest(entries: ["/Podcasts/Show/Episode.mp3": entry]),
                                            presentSizes: [entry.path: 1_000])
        let plan = await plan([show], selection: SyncSelection(mode: .allSongs), contents: contents)
        #expect(plan.copies.isEmpty && plan.updates.isEmpty && plan.moves.isEmpty)
    }

    @Test func removedDownloadsComeOffThePlayer() async {
        let entry = PlayerManifestEntry(path: "Podcasts/Show/Gone.mp3", source: nil)
        let contents = PlayerDeviceContents(manifest: PlayerSyncManifest(entries: ["/Podcasts/Show/Gone.mp3": entry]),
                                            presentSizes: [entry.path: 1_000])
        let plan = await plan([], selection: SyncSelection(mode: .allSongs), contents: contents,
                              missing: ["/Podcasts/Show/Gone.mp3"])
        #expect(plan.removals.map(\.path) == ["Podcasts/Show/Gone.mp3"])
    }

    @Test func eachPodcastGetsAPlaylistOldestFirst() async throws {
        let show = podcast("Show", episodes: ["Older", "Newer"])
        let plan = await plan([show], selection: SyncSelection(mode: .allSongs))
        let playlist = try #require(plan.playlists?.first)
        #expect(playlist.path == "Playlists/Show.m3u8")
        let entries = playlist.contents.split(separator: "\n").filter { !$0.hasPrefix("#") }
        #expect(entries == ["../Podcasts/Show/Older.mp3", "../Podcasts/Show/Newer.mp3"])
    }

    @Test func podcastPlaylistsCanBeTurnedOff() async {
        var config = config
        config.makesPodcastPlaylists = false
        let plan = await plan([podcast("Show", episodes: ["Episode"])], selection: SyncSelection(mode: .allSongs),
                              config: config)
        #expect(plan.playlists == [])
    }

    @Test func configsSavedBeforePodcastsGetAPodcastFolderAndPlaylists() throws {
        let older = ["id": "A", "name": "FiiO", "rootPath": "", "musicFolder": "Music"]
        let data = try PropertyListSerialization.data(fromPropertyList: older, format: .binary, options: 0)
        let config = try PropertyListDecoder().decode(AudioPlayerConfig.self, from: data)
        #expect(config.podcastPath == "Podcasts")
        #expect(config.makesPodcastPlaylists)
    }

    @Test func onlyRemovedDownloadsInThePodcastFolderAreMissing() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let root = folder.path(percentEncoded: false)
        let kept = folder.appending(path: "kept.mp3")
        try Data().write(to: kept)
        let gone = root + "/gone.mp3"
        let finder = PodcastMissingSourceFinder(folderPath: root)
        #expect(finder.missing([kept.path(percentEncoded: false), gone, "/Music/song.m4a"],
                               downloaded: [kept.path(percentEncoded: false)]) == [gone])
        #expect(PodcastMissingSourceFinder(folderPath: "/Volumes/Unplugged/Podcasts")
            .missing(["/Volumes/Unplugged/Podcasts/a.mp3"], downloaded: []).isEmpty)
    }
}
