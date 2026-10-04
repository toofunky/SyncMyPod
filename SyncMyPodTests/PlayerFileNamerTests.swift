import Foundation
import Testing
@testable import SyncMyPod

struct PlayerFileNamerTests {
    @Test(arguments: [
        ("AC/DC", "AC_DC"),
        ("What? Why: \"Now\"", "What_ Why_ _Now_"),
        ("...And Justice for All", "_..And Justice for All"),
        ("Trailing dots...", "Trailing dots"),
        ("   ", "Fallback"),
    ])
    func makesFATSafeComponents(name: String, expected: String) {
        #expect(PlayerFileNamer.safeComponent(name, fallback: "Fallback") == expected)
    }

    @Test func singleDiscAlbumsNumberTracksOnly() {
        #expect(PlayerFileNamer.numberPrefix(disc: 1, discCount: 1, track: 7, trackCount: 12) == "07")
        #expect(PlayerFileNamer.numberPrefix(disc: 0, discCount: 0, track: 3, trackCount: 0) == "03")
    }

    @Test func multiDiscAlbumsAddTheDisc() {
        #expect(PlayerFileNamer.numberPrefix(disc: 2, discCount: 2, track: 5, trackCount: 14) == "2-05")
        #expect(PlayerFileNamer.numberPrefix(disc: 2, discCount: 0, track: 5, trackCount: 0) == "2-05")
    }

    @Test func longAlbumsPadToTheirTrackCount() {
        #expect(PlayerFileNamer.numberPrefix(disc: 1, discCount: 1, track: 7, trackCount: 120) == "007")
    }

    @Test func untrackedSongsHaveNoPrefix() {
        #expect(PlayerFileNamer.numberPrefix(disc: 1, discCount: 2, track: 0, trackCount: 0) == nil)
    }

    @Test func numberedCopiesKeepTheExtension() {
        #expect(PlayerFileNamer.numbered("Music/A/Song.m4a", copy: 2) == "Music/A/Song (2).m4a")
    }

    @Test func relativePlaylistPathsClimbOutOfThePlaylistFolder() {
        #expect(M3U8Playlist.relativePath(from: "Playlists", to: "Music/A/B/Song.m4a") == "../Music/A/B/Song.m4a")
        #expect(M3U8Playlist.relativePath(from: "", to: "Music/A/Song.m4a") == "Music/A/Song.m4a")
        #expect(M3U8Playlist.relativePath(from: "Root/Lists", to: "Root/Music/Song.m4a") == "../Music/Song.m4a")
    }
}
