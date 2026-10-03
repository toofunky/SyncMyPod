import Foundation
import Testing
@testable import SyncMyPod

@MainActor
struct SyncSelectionTests {
    private func track(_ title: String, album: String, genre: String) -> LibraryTrack {
        let track = LibraryTrack(filePath: "/Music/Artist/\(album)/\(title).m4a")
        track.title = title
        track.artist = "Artist"
        track.album = album
        track.genre = genre
        return track
    }

    private var library: [LibraryTrack] {
        [track("One", album: "First", genre: "Rock"),
         track("Two", album: "Second", genre: "Jazz"),
         track("Three", album: "Third", genre: "Soul")]
    }

    private func titles(_ snapshots: [SyncTrackSnapshot]) -> [String] {
        snapshots.map(\.request.draft.title)
    }

    @Test func allSongsSelectsEverything() {
        let snapshots = library.map { $0.syncSnapshot(preservingAlbumArtist: false) }
        let result = SyncSelection(mode: .allSongs).partition(snapshots, syncedPlaylists: [])
        #expect(titles(result.selected) == ["One", "Two", "Three"])
        #expect(result.unselected.isEmpty)
    }

    @Test func customSelectsByAlbumAndGenre() {
        let tracks = library
        let snapshots = tracks.map { $0.syncSnapshot(preservingAlbumArtist: false) }
        let selection = SyncSelection(mode: .custom, albums: [tracks[0].syncAlbumKey], genres: ["Soul"])
        let result = selection.partition(snapshots, syncedPlaylists: [])
        #expect(titles(result.selected) == ["One", "Three"])
        #expect(titles(result.unselected) == ["Two"])
    }

    @Test func playlistSongsAreSelectedWhateverTheMode() {
        let tracks = library
        let snapshots = tracks.map { $0.syncSnapshot(preservingAlbumArtist: false) }
        let playlist = IPodPlaylistRequest(id: 1, name: "Mix", createdAt: .now,
                                           tracks: [tracks[1].syncRequest(preservingAlbumArtist: false)])
        let result = SyncSelection(mode: .custom).partition(snapshots, syncedPlaylists: [playlist])
        #expect(titles(result.selected) == ["Two"])
    }

    @Test func customSyncsOnlyChosenPlaylists() {
        let mix = SyncPlaylistSnapshot(key: "mix", request: IPodPlaylistRequest(id: 1, name: "Mix", createdAt: .now,
                                                                                tracks: []))
        let chill = SyncPlaylistSnapshot(key: "chill", request: IPodPlaylistRequest(id: 2, name: "Chill",
                                                                                    createdAt: .now, tracks: []))
        #expect(SyncSelection(mode: .custom, playlists: ["chill"]).playlists(in: [mix, chill]).map(\.name) == ["Chill"])
        #expect(SyncSelection(mode: .allSongs).playlists(in: [mix, chill]).count == 2)
    }
}
