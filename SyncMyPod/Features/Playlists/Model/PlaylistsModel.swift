import Foundation
import Observation
import SwiftData

/// Adds, imports, exports and deletes playlists for the Playlists section.
@Observable
@MainActor
final class PlaylistsModel {
    var message: String?
    var exportFile: M3UPlaylistFile?

    func delete(_ playlist: LibraryPlaylist, context: ModelContext) {
        context.delete(playlist)
    }

    /// Adds the songs of an `.m3u`/`.m3u8` file found in the library as a new playlist named after the file.
    /// `nil` when none were found; `message` says what was skipped.
    func importPlaylist(from url: URL, tracks: [LibraryTrack], after playlists: [LibraryPlaylist],
                        context: ModelContext) -> LibraryPlaylist? {
        let isScoped = url.startAccessingSecurityScopedResource()
        defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let paths = M3UPlaylistParser.paths(in: try M3UPlaylistParser.read(url))
            let result = PlaylistImporter.match(paths, in: tracks)
            message = result.summary
            guard !result.trackPaths.isEmpty else { return nil }
            let playlist = LibraryPlaylist(name: url.deletingPathExtension().lastPathComponent,
                                           trackPaths: result.trackPaths)
            playlist.sortIndex = LibraryPlaylist.nextSortIndex(after: playlists)
            context.insert(playlist)
            return playlist
        } catch {
            message = error.localizedDescription
            return nil
        }
    }

    func prepareExport(of playlist: LibraryPlaylist, tracks: [LibraryTrack]) {
        let entries = PlaylistEntry.entries(of: playlist, in: tracks)
        exportFile = M3UPlaylistFile(contents: PlaylistExporter.contents(of: entries))
    }

    func finishExport(_ result: Result<URL, any Error>) {
        do {
            _ = try result.get()
        } catch let error as CocoaError where error.code == .userCancelled {
            return
        } catch {
            message = error.localizedDescription
        }
    }
}
