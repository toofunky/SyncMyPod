import Foundation
import SwiftData
import Testing
@testable import SyncMyPod

@MainActor
struct AudiobookPlayerSyncTests {
    private let container = ModelContainer.makeInMemory()
    private let config = AudioPlayerConfig(name: "Player", rootPath: "", musicFolder: "Music",
                                           playlistFolder: "Playlists")

    /// Scanned files at `paths` under /Audiobooks, in the order given.
    private func book(_ title: String, author: String = "Mary Shelley", paths: [String],
                      codec: AudioCodec = .aac) -> Audiobook {
        let book = Audiobook(folderPath: "/Audiobooks/\(author)/\(title)", title: title)
        book.author = author
        container.mainContext.insert(book)
        book.files = paths.enumerated().map { index, path in
            let file = AudiobookFile(filePath: "/Audiobooks/\(author)/\(title)/\(path)")
            file.title = path
            file.trackNumber = index + 1
            file.fileSize = 1_000
            file.codecRawValue = codec.rawValue
            file.scanVersion = AudiobookFile.currentScanVersion
            return file
        }
        return book
    }

    private func plan(_ books: [Audiobook], selection: SyncSelection, config: AudioPlayerConfig? = nil,
                      contents: PlayerDeviceContents = PlayerDeviceContents()) async -> PlayerSyncPlan {
        let library = SyncLibrarySnapshot(tracks: [], playlists: [], audiobooks: books, preservingAlbumArtist: false)
        return await PlayerPlanInput(library: library, selection: selection, contents: contents,
                                     config: config ?? self.config, missingSources: [],
                                     sidecars: LibrarySidecars()).plan()
    }

    @Test func partsAreNumberedInListeningOrder() throws {
        let snapshot = try #require(book("Frankenstein", paths: ["b.mp3", "a.mp3"]).syncSnapshot())
        #expect(snapshot.files.map(\.tags.title) == ["b.mp3", "a.mp3"])
        #expect(snapshot.files.map(\.tags.trackNumber) == [1, 2])
        #expect(snapshot.files.allSatisfy {
            $0.kind == .audiobook && $0.source == nil && $0.tags.album == "Frankenstein" && $0.tags.albumArtist == "Mary Shelley"
        })
    }

    @Test func iPodRequestsAreAudiobooksWithASourceAndSkipUnplayableFiles() throws {
        let playable = try #require(book("Emma", author: "Jane Austen", paths: ["1.m4a"]).syncSnapshot(forIPod: true))
        #expect(playable.files.allSatisfy { $0.kind == .audiobook && $0.source != nil })
        #expect(book("Walden", author: "Thoreau", paths: ["1.flac"], codec: .flac).syncSnapshot(forIPod: true) == nil)
    }

    @Test func iPodCopiesWithoutArtworkTakeTheBooksCoverImage() throws {
        let book = book("Emma", author: "Jane Austen", paths: ["1.m4a", "2.m4a"])
        book.coverFilePath = "/Audiobooks/Jane Austen/Emma/cover.jpg"
        book.sortedFiles[1].artworkFingerprint = "embedded"
        let files = try #require(book.syncSnapshot(forIPod: true)).files
        #expect(files.map(\.coverImageURL?.lastPathComponent) == ["cover.jpg", nil])
        #expect(files[0].source?.artworkFingerprint?.hasPrefix("cover:") == true)
        #expect(files[1].source?.artworkFingerprint == "embedded")
    }

    @Test func booksGoInTheAudiobookFolderUnderAuthorAndTitle() async {
        let plan = await plan([book("Frankenstein", paths: ["01.mp3"])], selection: SyncSelection())
        #expect(plan.copies.map(\.destination) == ["Audiobooks/Mary Shelley/Frankenstein/01.mp3"])
    }

    @Test func discFoldersAreKeptSoTheirFilesDontCollide() async {
        let plan = await plan([book("Dune", author: "Frank Herbert", paths: ["CD 1/01.mp3", "CD 2/01.mp3"])],
                              selection: SyncSelection())
        #expect(plan.copies.map(\.destination).sorted() == ["Audiobooks/Frank Herbert/Dune/CD 1/01.mp3",
                                                            "Audiobooks/Frank Herbert/Dune/CD 2/01.mp3"])
    }

    @Test func customSyncCopiesOnlyChosenBooks() async {
        let chosen = book("Chosen", paths: ["1.mp3"])
        let other = book("Other", paths: ["1.mp3"])
        let plan = await plan([chosen, other], selection: SyncSelection(audiobookScope: .selected, audiobooks: [chosen.syncKey]))
        #expect(plan.copies.map(\.destination) == ["Audiobooks/Mary Shelley/Chosen/1.mp3"])
    }

    @Test func eachBookGetsAPlaylistInListeningOrder() async throws {
        let plan = await plan([book("Frankenstein", paths: ["02.mp3", "01.mp3"])],
                              selection: SyncSelection())
        let playlist = try #require(plan.playlists?.first)
        #expect(playlist.path == "Playlists/Frankenstein.m3u8")
        let entries = playlist.contents.split(separator: "\n").filter { !$0.hasPrefix("#") }
        #expect(entries == ["../Audiobooks/Mary Shelley/Frankenstein/02.mp3",
                            "../Audiobooks/Mary Shelley/Frankenstein/01.mp3"])
    }

    @Test func audiobookPlaylistsCanBeTurnedOff() async {
        var config = config
        config.makesAudiobookPlaylists = false
        let plan = await plan([book("Frankenstein", paths: ["01.mp3"])], selection: SyncSelection(),
                              config: config)
        #expect(plan.playlists == [])
    }

    @Test func playersSavedBeforeAudiobooksGetAnAudiobookFolderAndPlaylists() throws {
        let json = #"{"id":"1","name":"Player","rootPath":"","musicFolder":"Music"}"#
        let decoded = try JSONDecoder().decode(AudioPlayerConfig.self, from: Data(json.utf8))
        #expect(decoded.audiobookPath == "Audiobooks")
        #expect(decoded.makesAudiobookPlaylists)
    }

    @Test func removalsCountAudiobookFiles() {
        #expect(SyncRemovalWording.title(songs: 1, episodes: 0, audiobookFiles: 2, deviceKind: "iPod")
                == "Remove 1 song and 2 audiobook files from the iPod?")
    }
}
