import Foundation
import Testing
@testable import SyncMyPod

struct IPodPodcastSyncTests {
    private static let released = Date(timeIntervalSince1970: 1_792_047_600)
    private let fixture = ITunesDBFixtureBuilder(playlists: [FixturePlaylist(id: 1, name: "iPod", isMaster: true,
                                                                             trackIDs: [])],
                                                 includesAlbumSection: true, includesPodcastSection: true).build()

    private func episode(_ title: String, show: String, in volume: TemporaryIPodVolume) throws -> SyncRequest {
        var draft = TrackTags(title: title, artist: "Host", album: show, fileSize: 1_024)
        draft.releaseDate = Self.released
        return SyncRequest(sourceURL: try volume.makeSourceFile(named: "\(title).mp3"), tags: draft,
                               source: SyncSource(fileSize: 1_024, modificationDate: .distantPast,
                                                  artworkFingerprint: nil), kind: .podcast)
    }

    private func podcastsList(_ episodes: [SyncRequest]) -> SyncPlaylistRequest {
        SyncPlaylistRequest(id: SyncPlaylistRequest.podcastsID, name: "Podcasts", createdAt: .now, tracks: episodes,
                            isPodcasts: true)
    }

    private func list(_ section: ITunesDBSectionType, on volume: TemporaryIPodVolume) throws -> [ITunesDBRecord] {
        let root = try ITunesDBRecordParser(data: Data(contentsOf: volume.databaseURL)).parse()
        return root.children.first { $0.isSection(section) }?.children.first?.children ?? []
    }

    @Test func episodesAreMarkedAsPodcastsThatResumeAndSkipShuffle() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        _ = try await IPodTrackSyncer(volumeURL: volume.url).sync(adding: [try episode("One", show: "Show", in: volume)])
        let mhit = try #require(try list(.tracks, on: volume).first)
        #expect(mhit.uint32(at: 0xD0) == 4)
        #expect([0xA5, 0xA6, 0xA7].map { mhit.uint8(at: $0) } == [1, 1, 1])
        #expect(mhit.uint8(at: 0xB2) == 2)
        #expect(mhit.uint32(at: 0x8C) == ITunesTimestamp.seconds(from: Self.released, timeZone: .gmt))
    }

    @Test func songsKeepTheirMusicMediaType() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let song = SyncRequest(sourceURL: try volume.makeSourceFile(named: "song.m4a"),
                                   tags: TrackTags(title: "Song", fileSize: 1_024))
        _ = try await IPodTrackSyncer(volumeURL: volume.url).sync(adding: [song])
        let mhit = try #require(try list(.tracks, on: volume).first)
        #expect(mhit.uint32(at: 0xD0) == 1 && mhit.uint8(at: 0xA6) == 0 && mhit.uint8(at: 0xB2) == 0)
    }

    @Test func thePodcastsListIsGroupedByShowOnlyInThePodcastSection() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let episodes = [try episode("A1", show: "Alpha", in: volume), try episode("A2", show: "Alpha", in: volume),
                        try episode("B1", show: "Beta", in: volume)]
        _ = try await IPodTrackSyncer(volumeURL: volume.url).sync(adding: episodes, playlists: [podcastsList(episodes)])

        let flat = try #require(try list(.playlists, on: volume).first(where: ITunesDBPlaylistWriter.isPodcastList))
        #expect(flat.children.filter { $0.tag == "mhip" }.count == 3)
        let grouped = try #require(try list(.podcasts, on: volume).first(where: ITunesDBPlaylistWriter.isPodcastList))
        let items = grouped.children.filter { $0.tag == "mhip" }
        #expect(grouped.uint32(at: 0x10) == 5)
        let headers = items.filter { $0.uint32(at: 0x10) == 0x100 }
        #expect(headers.map { $0.string(ofType: 1) } == ["Alpha", "Beta"])
        #expect(items.map { $0.uint32(at: 0x10) == 0x100 ? 0 : $0.uint32(at: 0x20) }
                == [0, headers[0].uint32(at: 0x14), headers[0].uint32(at: 0x14), 0, headers[1].uint32(at: 0x14)])
    }

    @Test func eachSyncReplacesThePodcastsList() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let syncer = IPodTrackSyncer(volumeURL: volume.url)
        let first = try episode("One", show: "Show", in: volume)
        _ = try await syncer.sync(adding: [first], playlists: [podcastsList([first])])
        let second = try episode("Two", show: "Show", in: volume)
        _ = try await syncer.sync(adding: [second], playlists: [podcastsList([first, second])])
        for section in [ITunesDBSectionType.playlists, .podcasts] {
            #expect(try list(section, on: volume).filter(ITunesDBPlaylistWriter.isPodcastList).count == 1)
        }
        let database = try ITunesDBParser(data: Data(contentsOf: volume.databaseURL)).parse()
        let podcasts = try #require(database.playlists.first { $0.id == SyncPlaylistRequest.podcastsID })
        #expect(podcasts.trackIDs.compactMap { id in database.tracks.first { $0.id == id }?.title } == ["One", "Two"])
    }

    @Test func episodesAlreadyOnTheIPodAreLeftAsTheyAre() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let syncer = IPodTrackSyncer(volumeURL: volume.url)
        let episode = try episode("One", show: "Show", in: volume)
        _ = try await syncer.sync(adding: [episode])
        let again = try await syncer.sync(adding: [episode])
        #expect(again.skipped == 1 && again.addedCount == 0 && again.updatedCount == 0)
        #expect(try list(.tracks, on: volume).count == 1)
    }

    @Test func updatingAnEpisodeKeepsWhetherItWasPlayed() throws {
        let draft = ITunesTrackDraft(tags: TrackTags(title: "Episode", fileSize: 1), mediaKind: .podcast)
        let builder = TrackRecordBuilder(headerLength: TrackRecordBuilder.minimumHeaderLength)
        var mhit = builder.build(draft, id: 1, databaseID: 1, albumID: 0)
        mhit.set(TrackRecordBuilder.playedPodcast, at: TrackRecordBuilder.unplayedOffset)
        builder.apply(draft, to: &mhit, includingArtwork: false)
        #expect(mhit.uint8(at: TrackRecordBuilder.unplayedOffset) == TrackRecordBuilder.playedPodcast)
    }

    @Test func playingAnEpisodeClearsItsUnplayedDot() throws {
        let draft = ITunesTrackDraft(tags: TrackTags(title: "Episode", fileSize: 1), mediaKind: .podcast)
        var root = try ITunesDBRecordParser(data: fixture).parse()
        var editor = try ITunesDBEditor(root: root)
        _ = editor.addTrack(draft)
        root = editor.root
        #expect(PlayCountsMerger.merge([PlayCountEntry(playCount: 1)], into: &root))
        let mhit = try #require(root.children.first { $0.isSection(.tracks) }?.children.first?.children.first)
        #expect(mhit.uint8(at: TrackRecordBuilder.unplayedOffset) == TrackRecordBuilder.playedPodcast)
    }
}
