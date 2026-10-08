import Foundation
import Testing
@testable import SyncMyPod

struct PlaylistImportExportTests {
    private func track(_ path: String, artist: String, album: String, albumArtist: String = "") -> LibraryTrack {
        let track = LibraryTrack(filePath: path)
        track.title = URL(filePath: path).deletingPathExtension().lastPathComponent
        track.artist = artist
        track.album = album
        track.albumArtist = albumArtist
        track.duration = 200
        return track
    }

    @Test func parserSkipsCommentsAndNormalizesPaths() {
        let text = "\u{FEFF}#EXTM3U\r\n#EXTINF:1,a\r\n\r\n../A/B/c.mp3\r\nfile:///Music/A%20B/C/d.mp3\nC:\\M\\A\\B\\e.mp3\n"
        #expect(M3UPlaylistParser.paths(in: text) == ["../A/B/c.mp3", "/Music/A B/C/d.mp3", "C:/M/A/B/e.mp3"])
    }

    @Test func matchesAbsoluteAndRelativePathsByTagsAndFileName() {
        let library = [track("/Users/me/Music/Beyoncé/Lemonade/01 Pray.m4a", artist: "Beyoncé", album: "Lemonade")]
        let paths = ["/Volumes/Card/Music/Beyoncé/Lemonade/01 Pray.m4a", "../BEYONCE/lemonade/01 pray.m4a",
                     "Lemonade/01 Pray.m4a", "../Other/Lemonade/01 Pray.m4a"]
        let result = PlaylistImporter.match(paths, in: library)
        #expect(result.trackPaths == Array(repeating: library[0].filePath, count: 2))
        #expect(result.missingCount == 2)
        #expect(result.summary == "Imported 2 of 4 songs; 2 not found in your library.")
    }

    @Test func matchesAlbumArtistAndFATSafeFolderNames() {
        let library = [track("/Music/x/y/Hey Ya!.m4a", artist: "OutKast feat. X", album: "Speakerboxxx/The Love Below",
                             albumArtist: "OutKast")]
        let result = PlaylistImporter.match(["../OutKast/Speakerboxxx_The Love Below/Hey Ya!.m4a"], in: library)
        #expect(result.trackPaths == [library[0].filePath])
    }

    @Test func matchesFolderNamesWithSubstitutedColons() {
        let library = [track("/Music/x/y/01 Surfin' Safari.m4a", artist: "The Beach Boys",
                             album: "The Greatest Hits, Volume 1: 20 Good Vibrations")]
        let path = "The Beach Boys/The Greatest Hits, Volume 1; 20 Good Vibrations/01 Surfin' Safari.m4a"
        #expect(PlaylistImporter.match([path], in: library).trackPaths == [library[0].filePath])
    }

    @Test func keepsOrderAndDuplicates() {
        let first = track("/M/A/B/1.mp3", artist: "A", album: "B")
        let second = track("/M/A/B/2.mp3", artist: "A", album: "B")
        let result = PlaylistImporter.match(["x/A/B/2.mp3", "x/A/B/1.mp3", "x/A/B/2.mp3"], in: [first, second])
        #expect(result.trackPaths == [second.filePath, first.filePath, second.filePath])
        #expect(result.summary == nil)
    }

    @Test func exportsRelativePathsThatImportBack() {
        let library = [track("/Music/A/B/s.m4a", artist: "A", album: "B")]
        let playlist = LibraryPlaylist(name: "Mix", trackPaths: library.map(\.filePath) + ["/Music/Gone/X/y.mp3"])
        let entries = PlaylistEntry.entries(of: playlist, in: library)
        let text = PlaylistExporter.contents(of: entries, relativeTo: URL(filePath: "/Music/Playlists"))
        #expect(text == "#EXTM3U\n#EXTINF:200,A - s\n../A/B/s.m4a\n../Gone/X/y.mp3\n")
        let result = PlaylistImporter.match(M3UPlaylistParser.paths(in: text), in: library)
        #expect(result.trackPaths == [library[0].filePath])
    }
}
