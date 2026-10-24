import Foundation
import SwiftData
import Testing
@testable import SyncMyPod

@MainActor
struct AudiobookIPodSyncPlanTests {
    private let container = ModelContainer.makeInMemory()

    private func book(_ title: String, paths: [String]) -> Audiobook {
        let book = Audiobook(folderPath: "/Audiobooks/\(title)", title: title)
        container.mainContext.insert(book)
        book.files = paths.enumerated().map { index, path in
            let file = AudiobookFile(filePath: "/Audiobooks/\(title)/\(path)")
            file.title = path
            file.trackNumber = index + 1
            file.fileSize = 2_048
            file.codecRawValue = AudioCodec.aac.rawValue
            file.scanVersion = AudiobookFile.currentScanVersion
            return file
        }
        return book
    }

    private func plan(_ books: [Audiobook], selection: SyncSelection, playlists: Bool = true) async -> SyncPlan {
        let library = SyncLibrarySnapshot(tracks: [], playlists: [], audiobooks: books, forIPod: true,
                                          preservingAlbumArtist: false)
        let empty = ITunesDatabase(version: 0x19, databaseID: 1, tracks: [], playlists: [])
        return await SyncPlanInput(library: library, selection: selection, onDevice: empty,
                                   manifest: LoadedSyncManifest(), makesAudiobookPlaylists: playlists).plan()
    }

    @Test func eachChosenBookGetsAPlaylistOfItsPartsInOrder() async throws {
        let chosen = book("Frankenstein", paths: ["1.m4a", "2.m4a"])
        let other = book("Emma", paths: ["1.m4a"])
        let plan = await plan([chosen, other], selection: SyncSelection(audiobookScope: .selected, audiobooks: [chosen.syncKey]))
        #expect(plan.requests.map(\.sourcePath) == ["/Audiobooks/Frankenstein/1.m4a", "/Audiobooks/Frankenstein/2.m4a"])
        let playlist = try #require(plan.playlists.first)
        #expect(plan.playlists.count == 1)
        #expect(playlist.id == chosen.syncPlaylistID && playlist.name == "Frankenstein" && !playlist.isPodcasts)
        #expect(playlist.tracks.map(\.draft.title) == ["1.m4a", "2.m4a"])
    }

    @Test func playlistsCanBeTurnedOff() async {
        let plan = await plan([book("Frankenstein", paths: ["1.m4a"])], selection: SyncSelection(),
                              playlists: false)
        #expect(plan.playlists.isEmpty && plan.requests.count == 1)
    }

    @Test func eachBookKeepsItsPlaylistIDAcrossSyncs() {
        let book = book("Frankenstein", paths: ["1.m4a"])
        #expect(book.syncSnapshot(forIPod: true)?.playlist.id == book.syncPlaylistID)
        #expect(IPodSyncSettings(deviceID: "new").makesAudiobookPlaylists)
    }
}
