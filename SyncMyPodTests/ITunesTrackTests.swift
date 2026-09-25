import Foundation
import Testing
@testable import SyncMyPod

struct ITunesTrackTests {
    @Test func convertsColonPathToFileURL() {
        let track = ITunesTrack.preview(id: 1, title: "", artist: "", album: "", duration: 0)
            .withLocation(":iPod_Control:Music:F07:ABCD.mp3")
        let url = track.fileURL(onVolume: URL(filePath: "/Volumes/iPod", directoryHint: .isDirectory))
        #expect(url?.path == "/Volumes/iPod/iPod_Control/Music/F07/ABCD.mp3")
    }

    @Test func hasNoFileURLWithoutLocation() {
        let track = ITunesTrack.preview(id: 1, title: "", artist: "", album: "", duration: 0)
        #expect(track.fileURL(onVolume: URL(filePath: "/Volumes/iPod")) == nil)
    }
}

private extension ITunesTrack {
    func withLocation(_ location: String) -> ITunesTrack {
        var strings = strings
        strings[.location] = location
        return ITunesTrack(id: id, databaseID: databaseID, strings: strings, duration: duration,
                           fileSize: fileSize, trackNumber: trackNumber, trackCount: trackCount,
                           discNumber: discNumber, discCount: discCount, year: year, bitrate: bitrate,
                           sampleRate: sampleRate, rating: rating, playCount: playCount,
                           mediaType: mediaType, dateAdded: dateAdded, lastPlayed: lastPlayed,
                           lastModified: lastModified)
    }
}
