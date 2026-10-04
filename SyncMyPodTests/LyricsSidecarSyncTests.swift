import Foundation
import Testing
@testable import SyncMyPod

@MainActor
struct LyricsSidecarSyncTests {
    private let lyricsDate = Date(timeIntervalSinceReferenceDate: 800_000_000)
    private let fixture = ITunesDBFixtureBuilder(playlists: [
        FixturePlaylist(id: 1, name: "iPod", isMaster: true, trackIDs: [])
    ], includesAlbumSection: true).build()

    private func track(lyricFile: Bool, embedded: Bool = false) -> LibraryTrack {
        let track = LibraryTrack(filePath: "/Music/Coldplay/A Rush of Blood to the Head/Clocks.m4a")
        track.title = "Clocks"
        track.scanVersion = LibraryTrack.currentScanVersion
        track.hasLyrics = lyricFile
        track.lyricsFileDate = lyricFile ? lyricsDate : nil
        track.hasLyricsTag = embedded
        return track
    }

    @Test func embedsTheLyricFileOnlyWhenTurnedOn() {
        let off = track(lyricFile: true).syncRequest(preservingAlbumArtist: false)
        let on = track(lyricFile: true).syncRequest(preservingAlbumArtist: false, embeddingLyricsSidecar: true)
        #expect(!off.embedsLyricsSidecar && !off.draft.hasLyrics && off.source?.hasLyrics == nil)
        #expect(on.embedsLyricsSidecar && on.draft.hasLyrics)
        #expect(on.source?.hasLyrics == true && on.source?.lyricsSidecarDate == lyricsDate)
        #expect(on.source != off.source)
    }

    @Test func songsWithoutALyricFileOrWithTheirOwnLyricsAreLeftAlone() {
        let plain = track(lyricFile: false).syncRequest(preservingAlbumArtist: false, embeddingLyricsSidecar: true)
        let sung = track(lyricFile: true, embedded: true)
            .syncRequest(preservingAlbumArtist: false, embeddingLyricsSidecar: true)
        #expect(!plain.embedsLyricsSidecar && !plain.draft.hasLyrics)
        #expect(!sung.embedsLyricsSidecar && sung.draft.hasLyrics && sung.source?.lyricsSidecarDate == nil)
    }

    @Test(arguments: ["Clocks.mp3", "Clocks.m4a"])
    func writesPlainLyricsIntoTheCopy(name: String) async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let request = try await sidecarRequest(on: volume, name: name, lyrics: "[ar:Coldplay]\n[00:12.34]Lights go out")
        _ = try await IPodTrackSyncer(volumeURL: volume.url).sync(adding: [request])

        let mhit = try #require(try trackRecords(on: volume).first)
        let copy = try #require(try ITunesDBParser(data: Data(contentsOf: volume.databaseURL)).parse().tracks.first?
            .fileURL(onVolume: volume.url))
        #expect(try #require(try await AudioMetadataReader().read(copy)).tags.hasLyrics)
        #expect(mhit.uint8(at: 0xB0) == 1)
        #expect(Int(mhit.uint32(at: 0x24)) == (try copy.resourceValues(forKeys: [.fileSizeKey]).fileSize))
        #expect(try Data(contentsOf: request.sourceURL) != Data(contentsOf: copy))
    }

    @Test func emptyLyricFileLeavesTheCopyAndFlagAlone() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let request = try await sidecarRequest(on: volume, name: "Clocks.mp3", lyrics: "[ar:Coldplay]\n")
        _ = try await IPodTrackSyncer(volumeURL: volume.url).sync(adding: [request])

        #expect(try trackRecords(on: volume).first?.uint8(at: 0xB0) == 0)
    }

    private func sidecarRequest(on volume: TemporaryIPodVolume, name: String,
                                lyrics: String) async throws -> IPodSyncRequest {
        let source = volume.url.appending(path: "Library/\(name)")
        if name.hasSuffix(".mp3") {
            try MP3FixtureWriter.write(to: source, tags: ["TIT2": "Clocks"])
        } else {
            try AudioFixtureWriter.writeSilence(to: source)
        }
        try await LyricsFile.write(lyrics, forSongAt: source.path(percentEncoded: false))
        let size = try #require(try source.resourceValues(forKeys: [.fileSizeKey]).fileSize)
        let draft = ITunesTrackDraft(title: "Clocks", fileSize: size, codec: name.hasSuffix(".mp3") ? .mp3 : .aac,
                                     hasLyrics: true)
        return IPodSyncRequest(sourceURL: source, draft: draft, embedsLyricsSidecar: true)
    }

    private func trackRecords(on volume: TemporaryIPodVolume) throws -> [ITunesDBRecord] {
        let root = try ITunesDBRecordParser(data: Data(contentsOf: volume.databaseURL)).parse()
        return try #require(root.children.first { $0.isSection(.tracks) }?.children.first).children
    }
}
