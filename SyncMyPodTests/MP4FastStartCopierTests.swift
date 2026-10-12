import AVFoundation
import Foundation
import Testing
@testable import SyncMyPod

struct MP4FastStartCopierTests {
    private let folder: URL

    init() throws {
        folder = try AudioFixtureWriter.makeTemporaryFolder()
    }

    @Test(arguments: [kAudioFormatMPEG4AAC, kAudioFormatAppleLossless])
    func lateMovieBoxesAreMovedInFrontOfTheUnchangedAudio(format: AudioFormatID) throws {
        let late = try lateMovieFixture(format: format)
        let copy = folder.appending(path: "copy.m4a")
        #expect(try MP4FastStartCopier().copy(late, to: copy))
        let types = try topLevelBoxes(of: copy).map(\.type)
        #expect(try #require(types.firstIndex(of: .moov)) < #require(types.firstIndex(of: .mdat)))
        #expect(try mediaData(of: copy) == mediaData(of: late))
        #expect(try AVAudioFile(forReading: copy).length == AVAudioFile(forReading: late).length)
    }

    @Test func fastStartedCopiesStillReadAndRetagInPlace() async throws {
        let copy = folder.appending(path: "copy.m4a")
        _ = try MP4FastStartCopier().copy(try lateMovieFixture(format: kAudioFormatAppleLossless), to: copy)
        let size = try FileManager.default.attributesOfItem(atPath: copy.path(percentEncoded: false))[.size] as? Int
        try MP4TagWriter().write(TagChanges(title: "Never Gonna Say I'm Sorry"), to: copy)
        #expect(try FileManager.default.attributesOfItem(atPath: copy.path(percentEncoded: false))[.size] as? Int == size)
        #expect(try await AudioMetadataReader().read(copy)?.tags.title == "Never Gonna Say I'm Sorry")
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: try AVAudioFile(forReading: copy).processingFormat,
                                                   frameCapacity: 4_096))
        try AVAudioFile(forReading: copy).read(into: buffer)
        #expect(buffer.frameLength > 0)
    }

    @Test func filesWhoseMovieBoxComesFirstAreLeftForAPlainCopy() throws {
        let source = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "front.m4a"))
        let copy = folder.appending(path: "copy.m4a")
        #expect(try !MP4FastStartCopier().copy(source, to: copy))
        #expect(!FileManager.default.fileExists(atPath: copy.path(percentEncoded: false)))
    }

    @Test func otherFilesAreLeftForAPlainCopy() throws {
        let source = folder.appending(path: "cover.jpg")
        try Data("not a movie".utf8).write(to: source)
        let mislabeled = folder.appending(path: "broken.m4a")
        try Data("not a movie either".utf8).write(to: mislabeled)
        #expect(try !MP4FastStartCopier().copy(source, to: folder.appending(path: "a")))
        #expect(try !MP4FastStartCopier().copy(mislabeled, to: folder.appending(path: "b")))
    }

    @Test func syncingToAPlayerPutsTheMovieBoxFirst() async throws {
        let config = AudioPlayerConfig(name: "Player", rootPath: "", musicFolder: "Music")
        let volume = try TemporaryPlayerVolume(config: config)
        let source = try lateMovieFixture(format: kAudioFormatAppleLossless)
        let draft = ITunesTrackDraft(title: "Song", artist: "Artist", album: "Album", fileSize: 1, codec: .alac)
        let request = IPodSyncRequest(sourceURL: source, draft: draft,
                                      source: SyncSource(fileSize: 1, modificationDate: .now, artworkFingerprint: nil))
        let plan = await PlayerDeviceContents.load(from: try volume.device).planner(for: config)
            .plan(selected: [request], playlists: nil)
        _ = try await PlayerTrackSyncer(device: volume.device).sync(plan)
        let types = try topLevelBoxes(of: volume.volumeURL.appending(path: "Music/Artist/Album/late.m4a")).map(\.type)
        #expect(try #require(types.firstIndex(of: .moov)) < #require(types.firstIndex(of: .mdat)))
    }

    /// An Apple-encoded song rewritten with its `moov` box last, as some ffmpeg-based encoders leave it.
    private func lateMovieFixture(format: AudioFormatID) throws -> URL {
        let front = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "front-\(format).m4a"),
                                                        format: format)
        let data = try Data(contentsOf: front)
        let boxes = try topLevelBoxes(of: front)
        let moovIndex = try #require(boxes.firstIndex { $0.type == .moov })
        let padding = boxes[(moovIndex + 1)...].prefix { $0.type == .free }
        let removed = boxes[moovIndex].range.lowerBound..<(padding.last?.range.upperBound ?? boxes[moovIndex].range.upperBound)
        var moov = try #require(try MP4BoxParser.parse(data.subdata(in: boxes[moovIndex].range)).first)
        try MP4ChunkOffsetShifter.shift(&moov, by: -removed.count, from: removed.upperBound)
        let late = folder.appending(path: "late.m4a")
        try (data.subdata(in: 0..<removed.lowerBound) + data.subdata(in: removed.upperBound..<data.count)
             + moov.serialized()).write(to: late)
        let types = try topLevelBoxes(of: late).map(\.type)
        try #require(try #require(types.firstIndex(of: .moov)) > #require(types.firstIndex(of: .mdat)))
        return late
    }

    private func topLevelBoxes(of url: URL) throws -> [MP4TopLevelBox] {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        return try MP4TopLevelBox.scan(handle, fileSize: Int(try handle.seekToEnd()))
    }

    private func mediaData(of url: URL) throws -> Data {
        let range = try #require(try topLevelBoxes(of: url).first { $0.type == .mdat }).range
        return try Data(contentsOf: url).subdata(in: range)
    }
}
