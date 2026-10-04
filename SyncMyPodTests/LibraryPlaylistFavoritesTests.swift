import SwiftData
import Testing
@testable import SyncMyPod

struct LibraryPlaylistFavoritesTests {
    let context: ModelContext

    init() throws {
        let container = try ModelContainer(for: Schema(MusicLibrarySchema.models),
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        context = ModelContext(container)
    }

    @Test func ensureFavoritesCreatesExactlyOnePlaylist() throws {
        let first = LibraryPlaylist.ensureFavorites(in: context)
        let second = LibraryPlaylist.ensureFavorites(in: context)
        #expect(first.playlistID == second.playlistID)
        #expect(first.name == LibraryPlaylist.favoritesName)
        #expect(try context.fetch(FetchDescriptor<LibraryPlaylist>()).count == 1)
    }

    @Test func favoritingSkipsSongsAlreadyFavorited() {
        let favorites = LibraryPlaylist.ensureFavorites(in: context)
        let tracks = [LibraryTrack(filePath: "/Music/a.m4a"), LibraryTrack(filePath: "/Music/b.m4a")]
        favorites.setFavorite([tracks[0]], true)
        favorites.setFavorite(tracks + [tracks[1]], true)
        #expect(favorites.trackPaths == ["/Music/a.m4a", "/Music/b.m4a"])
        #expect(favorites.isFavorite(tracks[1]))
    }

    @Test func unfavoritingRemovesEveryCopy() {
        let favorites = LibraryPlaylist.ensureFavorites(in: context)
        let track = LibraryTrack(filePath: "/Music/a.m4a")
        favorites.trackPaths = ["/Music/a.m4a", "/Music/b.m4a", "/Music/a.m4a"]
        favorites.setFavorite([track], false)
        #expect(favorites.trackPaths == ["/Music/b.m4a"])
        #expect(!favorites.isFavorite(track))
    }

    @Test func renamedFavoritesIsStillFound() {
        let favorites = LibraryPlaylist.ensureFavorites(in: context)
        favorites.name = "Favorite Songs"
        let found = LibraryPlaylist.ensureFavorites(in: context)
        #expect(found.playlistID == favorites.playlistID)
        #expect(found.isFavorites)
        #expect(found.name == "Favorite Songs")
    }

    @Test func ordinaryPlaylistsAreNotFavorites() {
        #expect(!LibraryPlaylist(name: "Road Trip").isFavorites)
    }
}
