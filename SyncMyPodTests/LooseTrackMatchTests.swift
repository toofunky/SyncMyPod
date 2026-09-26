import Foundation
import Testing
@testable import SyncMyPod

struct LooseTrackMatchTests {
    private func request(_ title: String, artist: String, album: String = "The Sign", duration: TimeInterval = 192.445,
                         path: String = "/Music/Main/04 The Sign.m4a") -> IPodSyncRequest {
        let source = SyncSource(fileSize: 6_088_211, modificationDate: .distantPast, artworkFingerprint: "cover")
        return IPodSyncRequest(sourceURL: URL(filePath: path),
                               draft: ITunesTrackDraft(title: title, artist: artist, album: album,
                                                       fileSize: 6_088_211, duration: duration),
                               source: source)
    }

    private func onIPod(_ title: String, artist: String, album: String = "The Sign", duration: TimeInterval = 192.445,
                        id: UInt32) -> ITunesTrack {
        ITunesTrack(id: id, databaseID: UInt64(id) * 10, strings: [.title: title, .artist: artist, .album: album],
                    duration: duration, fileSize: 6_088_211, trackNumber: 0, trackCount: 0, discNumber: 0,
                    discCount: 0, year: 0, bitrate: 0, sampleRate: 0, rating: 0, playCount: 0, mediaType: 1,
                    dateAdded: nil, lastPlayed: nil, lastModified: nil)
    }

    @Test func needsTheSameDurationAndTwoMatchingTags() {
        let edited = request("The Sign", artist: "Ace of Base Test")
        #expect(LooseTrackMatch.matches(edited, onIPod("The Sign", artist: "Ace of Base", id: 1)))
        #expect(LooseTrackMatch.matches(edited, onIPod("the sign ", artist: "Ace of Base", duration: 192.446, id: 1)))
        #expect(!LooseTrackMatch.matches(edited, onIPod("The Sign", artist: "Ace of Base", duration: 192.6, id: 1)))
        #expect(!LooseTrackMatch.matches(edited, onIPod("The Sign", artist: "Ace of Base", album: "Hits", id: 1)))
        #expect(!LooseTrackMatch.matches(request("The Sign", artist: "A", duration: 0),
                                         onIPod("The Sign", artist: "B", duration: 0, id: 1)))
    }

    @Test func adoptsTheOneLooseMatchWithoutASource() {
        var manifest = SyncManifest()
        let edited = request("The Sign", artist: "Ace of Base Test")
        let adopted = manifest.adoptLoosely([edited], onDevice: [onIPod("The Sign", artist: "Ace of Base", id: 1)])
        #expect(adopted)
        #expect(manifest.entry(for: edited) == SyncManifestEntry(databaseID: 10, source: nil))
    }

    @Test func skipsAmbiguousClaimedOrExactlyMatchedTracks() {
        let edited = request("The Sign", artist: "Ace of Base Test")
        var manifest = SyncManifest()
        let twoCandidates = [onIPod("The Sign", artist: "Ace of Base", id: 1),
                             onIPod("The Sign", artist: "Ace", id: 2)]
        let exact = [onIPod("The Sign", artist: "Ace of Base Test", id: 3), onIPod("The Sign", artist: "Ace", id: 4)]
        let first = manifest.adoptLoosely([edited], onDevice: twoCandidates)
        let second = manifest.adoptLoosely([edited], onDevice: exact)
        #expect(!first && !second)
        var claimed = SyncManifest().recording([request("Other", artist: "X", path: "/o.m4a")], as: ["/o.m4a": 10])
        let third = claimed.adoptLoosely([edited], onDevice: [onIPod("The Sign", artist: "Ace of Base", id: 1)])
        #expect(!third)
    }

    @Test func findsTheCopyLeftBehindByAnEarlierEdit() {
        let edited = request("The Sign", artist: "Ace of Base Test")
        let manifest = SyncManifest().recording([edited], as: [edited.sourcePath: 20])
        let onDevice = [onIPod("The Sign", artist: "Ace of Base", id: 1),
                        onIPod("The Sign", artist: "Ace of Base Test", id: 2),
                        onIPod("The Sign", artist: "Ace of Base", album: "Greatest Hits", duration: 200, id: 3)]
        #expect(manifest.duplicates(among: onDevice, of: [edited]) == [10])
    }

    @Test func aTrackMatchingALibraryFilesTagsIsNeverADuplicate() {
        let edited = request("The Sign", artist: "Ace of Base Test")
        let original = request("The Sign", artist: "Ace of Base", path: "/Music/Old/The Sign.m4a")
        let manifest = SyncManifest().recording([edited], as: [edited.sourcePath: 20])
        let onDevice = [onIPod("The Sign", artist: "Ace of Base", id: 1),
                        onIPod("The Sign", artist: "Ace of Base Test", id: 2)]
        #expect(manifest.duplicates(among: onDevice, of: [edited, original]).isEmpty)
    }
}
