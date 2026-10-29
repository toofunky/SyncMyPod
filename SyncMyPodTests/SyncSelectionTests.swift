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
        let result = SyncSelection().partition(snapshots, syncedPlaylists: [])
        #expect(titles(result.selected) == ["One", "Two", "Three"])
        #expect(result.unselected.isEmpty)
    }

    @Test func customSelectsByAlbumAndGenre() {
        let tracks = library
        let snapshots = tracks.map { $0.syncSnapshot(preservingAlbumArtist: false) }
        let selection = SyncSelection(songs: .selected, albums: [tracks[0].syncAlbumKey], genres: ["Soul"])
        let result = selection.partition(snapshots, syncedPlaylists: [])
        #expect(titles(result.selected) == ["One", "Three"])
        #expect(titles(result.unselected) == ["Two"])
    }

    @Test func playlistSongsAreSelectedWhateverTheSongScope() {
        let tracks = library
        let snapshots = tracks.map { $0.syncSnapshot(preservingAlbumArtist: false) }
        let playlist = SyncPlaylistRequest(id: 1, name: "Mix", createdAt: .now,
                                           tracks: [tracks[1].syncRequest(preservingAlbumArtist: false)])
        let result = SyncSelection(songs: .none).partition(snapshots, syncedPlaylists: [playlist])
        #expect(titles(result.selected) == ["Two"])
    }

    @Test func selectedSyncsOnlyChosenPlaylists() {
        let mix = SyncPlaylistSnapshot(key: "mix", request: SyncPlaylistRequest(id: 1, name: "Mix", createdAt: .now,
                                                                                tracks: []))
        let chill = SyncPlaylistSnapshot(key: "chill", request: SyncPlaylistRequest(id: 2, name: "Chill",
                                                                                    createdAt: .now, tracks: []))
        #expect(SyncSelection(playlistScope: .selected, playlists: ["chill"]).playlists(in: [mix, chill]).map(\.name) == ["Chill"])
        #expect(SyncSelection().playlists(in: [mix, chill]).count == 2)
    }

    @Test func noPlaylistsSyncWhenTheirScopeIsNone() {
        let mix = SyncPlaylistSnapshot(key: "mix", request: SyncPlaylistRequest(id: 1, name: "Mix", createdAt: .now,
                                                                                tracks: []))
        #expect(SyncSelection(playlistScope: .none, playlists: ["mix"]).playlists(in: [mix]).isEmpty)
    }

    @Test func noSongsSyncWhenTheirScopeIsNoneWhateverIsChosen() {
        let tracks = library
        let snapshots = tracks.map { $0.syncSnapshot(preservingAlbumArtist: false) }
        let selection = SyncSelection(songs: .none, albums: [tracks[0].syncAlbumKey], genres: ["Soul"])
        #expect(selection.partition(snapshots, syncedPlaylists: []).selected.isEmpty)
    }

    @Test func podcastsFollowTheirOwnScope() {
        let shows = ["chosen", "other"].map { SyncPodcastSnapshot(key: $0, playlist: SyncPlaylistRequest(
            id: 1, name: $0, createdAt: .now, tracks: [])) }
        let chosen = SyncSelection(podcastScope: .selected, podcasts: ["chosen"]).partition(shows)
        #expect(chosen.selected.map(\.key) == ["chosen"] && chosen.unselected.map(\.key) == ["other"])
        let none = SyncSelection(podcastScope: .none, podcasts: ["chosen"]).partition(shows)
        #expect(none.selected.isEmpty && none.unselected.count == 2)
    }

    @Test func allSongsWithSelectedPodcastsSyncsEverySong() {
        let snapshots = library.map { $0.syncSnapshot(preservingAlbumArtist: false) }
        let selection = SyncSelection(songs: .all, podcastScope: .selected)
        #expect(selection.partition(snapshots, syncedPlaylists: []).selected.count == 3)
    }
}
