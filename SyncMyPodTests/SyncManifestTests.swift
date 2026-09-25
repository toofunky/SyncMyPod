import Foundation
import Testing
@testable import SyncMyPod

struct SyncManifestTests {
    private let source = SyncSource(fileSize: 1_024,
                                    modificationDate: Date(timeIntervalSinceReferenceDate: 812_345.678),
                                    artworkFingerprint: "abc")

    private func request(_ title: String, path: String? = nil, scanned: Bool = true) -> IPodSyncRequest {
        IPodSyncRequest(sourceURL: URL(filePath: path ?? "/Music/\(title).m4a"),
                        draft: ITunesTrackDraft(title: title, artist: "A", album: "B", fileSize: 1_024),
                        source: scanned ? source : nil)
    }

    private func deviceTrack(_ title: String, id: UInt32) -> ITunesTrack {
        ITunesTrack(id: id, databaseID: UInt64(id) * 10, strings: [.title: title, .artist: "A", .album: "B"],
                    duration: 0, fileSize: 1_024, trackNumber: 0, trackCount: 0, discNumber: 0, discCount: 0,
                    year: 0, bitrate: 0, sampleRate: 0, rating: 0, playCount: 0, mediaType: 1,
                    dateAdded: nil, lastPlayed: nil, lastModified: nil)
    }

    @Test func roundTripsThroughTheIPodExactly() throws {
        let volume = try TemporaryIPodVolume(database: nil)
        let files = IPodControlFiles(volumeURL: volume.url)
        let manifest = SyncManifest().recording([request("One")], as: ["/Music/One.m4a": 7])
        try files.save(manifest)
        #expect(files.manifest() == manifest)
        #expect(files.manifest().entry(for: request("One"))?.source == source)
    }

    @Test func missingOrCorruptFileReadsAsEmpty() throws {
        let volume = try TemporaryIPodVolume(database: nil)
        let files = IPodControlFiles(volumeURL: volume.url)
        #expect(files.manifest() == SyncManifest())
        try Data("junk".utf8).write(to: files.manifestURL)
        #expect(files.manifest() == SyncManifest())
    }

    @Test func dropsEntriesForTracksNoLongerOnTheIPod() {
        let manifest = SyncManifest().recording([request("One"), request("Two")],
                                                as: ["/Music/One.m4a": 10, "/Music/Two.m4a": 20])
        let valid = manifest.valid(for: [20])
        #expect(valid.entry(for: request("One")) == nil)
        #expect(valid.entry(for: request("Two"))?.databaseID == 20)
    }

    @Test func recordingSkipsRequestsWithoutSourceDetails() {
        let manifest = SyncManifest().recording([request("One", scanned: false)], as: ["/Music/One.m4a": 10])
        #expect(manifest.entries.isEmpty)
    }

    @Test func adoptsEachIPodTrackOnce() {
        var manifest = SyncManifest()
        let copies = [request("One", path: "/Music/a/One.m4a"), request("One", path: "/Music/b/One.m4a")]
        let adopted = manifest.adopt(copies, onDevice: [deviceTrack("One", id: 1)])
        #expect(adopted)
        #expect(manifest.entries.count == 1)
        #expect(manifest.claimedDatabaseIDs == [10])
    }

    @Test func adoptionSkipsUnscannedFilesAndKnownFiles() {
        var manifest = SyncManifest().recording([request("One")], as: ["/Music/One.m4a": 10])
        let onDevice = [deviceTrack("One", id: 2), deviceTrack("Two", id: 3)]
        let adopted = manifest.adopt([request("One"), request("Two", scanned: false)], onDevice: onDevice)
        #expect(!adopted)
        #expect(manifest.entry(for: request("One"))?.databaseID == 10)
    }

    @Test func loadingAdoptsAndSavesOnlyWhenSomethingWasAdded() async throws {
        let volume = try TemporaryIPodVolume(database: nil)
        let files = IPodControlFiles(volumeURL: volume.url)
        let loaded = await files.manifest(adopting: [request("One", scanned: false)],
                                          onDevice: [deviceTrack("One", id: 1)], libraryFolder: nil)
        #expect(loaded.manifest.entries.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: files.manifestURL.path(percentEncoded: false)))
        _ = await files.manifest(adopting: [request("One")], onDevice: [deviceTrack("One", id: 1)], libraryFolder: nil)
        #expect(files.manifest().entry(for: request("One"))?.databaseID == 10)
    }

    @Test func relinksARenamedFileToItsCopy() {
        var manifest = SyncManifest().recording([request("One", path: "/Music/Old.m4a")], as: ["/Music/Old.m4a": 10])
        let renamed = request("One", path: "/Music/New.m4a")
        let moved = manifest.relink([renamed], onDevice: [deviceTrack("One", id: 1)], missing: ["/Music/Old.m4a"])
        #expect(moved)
        #expect(manifest.entry(for: renamed)?.databaseID == 10)
        #expect(manifest.entries["/Music/Old.m4a"] == nil)
    }

    @Test func relinkingNeedsMatchingTags() {
        var manifest = SyncManifest().recording([request("One", path: "/Music/Old.m4a")], as: ["/Music/Old.m4a": 10])
        let moved = manifest.relink([request("Retitled", path: "/Music/New.m4a")], onDevice: [deviceTrack("One", id: 1)],
                                    missing: ["/Music/Old.m4a"])
        #expect(!moved)
        #expect(manifest.entries["/Music/Old.m4a"]?.databaseID == 10)
    }

    @Test func findsOnlyDeletedFilesInsideAReachableLibrary() throws {
        let volume = try TemporaryIPodVolume(database: nil)
        let folder = volume.url.appending(path: "Music").path(percentEncoded: false)
        let kept = try volume.makeSourceFile(named: "Music/Kept.m4a").path(percentEncoded: false)
        let finder = MissingSourceFinder(folderPath: folder)
        let paths = ["\(folder)/Gone.m4a", kept, "/Other/Gone.m4a"]
        #expect(finder.missing(paths, notIn: [kept]) == ["\(folder)/Gone.m4a"])
        #expect(finder.missing(paths, notIn: []).isEmpty)
        #expect(MissingSourceFinder(folderPath: "/Volumes/Unplugged").missing(["/Volumes/Unplugged/A.m4a"],
                                                                              notIn: []).isEmpty)
    }

    @Test func loadingRelinksBeforeAdoptingAndReportsOrphans() async throws {
        let volume = try TemporaryIPodVolume(database: nil)
        let folder = volume.url.appending(path: "Music").path(percentEncoded: false)
        let renamed = request("One", path: try volume.makeSourceFile(named: "Music/New.m4a").path(percentEncoded: false))
        let files = IPodControlFiles(volumeURL: volume.url)
        try files.save(SyncManifest().recording([request("One", path: "\(folder)/Old.m4a"),
                                                 request("Two", path: "\(folder)/Deleted.m4a")],
                                                as: ["\(folder)/Old.m4a": 10, "\(folder)/Deleted.m4a": 20]))
        let loaded = await files.manifest(adopting: [renamed], onDevice: [deviceTrack("One", id: 1),
                                                                         deviceTrack("Two", id: 2)],
                                          libraryFolder: folder)
        #expect(loaded.manifest.entry(for: renamed)?.databaseID == 10)
        #expect(loaded.strayDatabaseIDs == [20])
        #expect(files.manifest() == loaded.manifest)
    }
}
