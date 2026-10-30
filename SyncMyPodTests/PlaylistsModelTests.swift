import Foundation
import SwiftData
import Testing
@testable import SyncMyPod

@MainActor
struct PlaylistsModelTests {
    let context: ModelContext
    let folder: URL

    init() throws {
        let container = try ModelContainer(for: Schema(MusicLibrarySchema.models),
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        context = ModelContext(container)
        folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    private func playlistFile(_ lines: [String]) throws -> URL {
        let url = folder.appending(path: "Road Trip.m3u8")
        try (["#EXTM3U"] + lines).joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func playlists() throws -> [LibraryPlaylist] {
        try context.fetch(FetchDescriptor<LibraryPlaylist>())
    }

    @Test func importAddsMatchedSongsAsTheLastPlaylist() throws {
        let existing = LibraryPlaylist(name: "Older", trackPaths: [])
        existing.sortIndex = 4
        context.insert(existing)
        let track = LibraryTrack(filePath: "/Music/Muse/Absolution/01 Intro.m4a")
        track.artist = "Muse"
        track.album = "Absolution"
        let model = PlaylistsModel()
        let file = try playlistFile(["Muse/Absolution/01 Intro.m4a", "Muse/Absolution/gone.m4a"])
        let imported = try #require(model.importPlaylist(from: file, tracks: [track], after: [existing],
                                                         context: context))
        #expect(imported.name == "Road Trip" && imported.trackPaths == [track.filePath])
        #expect(imported.sortIndex == 5)
        #expect(try playlists().count == 2)
        #expect(model.message == "Imported 1 of 2 songs; 1 not found in your library.")
    }

    @Test func importWithNoMatchesAddsNothing() throws {
        let model = PlaylistsModel()
        let imported = model.importPlaylist(from: try playlistFile(["/Music/gone.m4a"]), tracks: [], after: [],
                                            context: context)
        #expect(imported == nil)
        #expect(try playlists().isEmpty)
        #expect(model.message == "None of the songs were found in your library.")
    }

    @Test func unreadableFileReportsAnError() {
        let model = PlaylistsModel()
        #expect(model.importPlaylist(from: folder.appending(path: "missing.m3u"), tracks: [], after: [],
                                     context: context) == nil)
        #expect(model.message != nil)
    }

    @Test func deleteRemovesThePlaylist() throws {
        let playlist = LibraryPlaylist(name: "Gone", trackPaths: [])
        context.insert(playlist)
        PlaylistsModel().delete(playlist, context: context)
        #expect(try playlists().isEmpty)
    }

    @Test func exportListsThePlaylistsSongsRelativeToTheMusicFolder() {
        let model = PlaylistsModel()
        let playlist = LibraryPlaylist(name: "Mix", trackPaths: ["/Users/me/Music/Muse/Absolution/01 Intro.m4a"])
        model.prepareExport(of: playlist, tracks: [])
        #expect(model.exportFile?.contents == "#EXTM3U\nMuse/Absolution/01 Intro.m4a\n")
    }

    @Test func cancelledExportIsNotAnError() {
        let model = PlaylistsModel()
        model.finishExport(.failure(CocoaError(.userCancelled)))
        #expect(model.message == nil)
        model.finishExport(.failure(CocoaError(.fileWriteNoPermission)))
        #expect(model.message != nil)
    }
}
