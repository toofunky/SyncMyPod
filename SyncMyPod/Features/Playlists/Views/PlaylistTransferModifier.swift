import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Imports `.m3u`/`.m3u8` files as new playlists and exports playlists as `.m3u8`.
struct PlaylistTransferModifier: ViewModifier {
    @Binding var isImporting: Bool
    @Binding var exportTarget: LibraryPlaylist?
    @Binding var selection: UUID?

    @Environment(\.modelContext) private var context
    @Query private var tracks: [LibraryTrack]
    @Query(sort: LibraryPlaylist.sidebarOrder) private var playlists: [LibraryPlaylist]
    @State private var exportFile: M3UPlaylistFile?
    @State private var exportEntries: [PlaylistEntry] = []
    @State private var message: String?

    func body(content: Content) -> some View {
        content
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.m3uPlaylist]) { result in
                if case .success(let url) = result { importPlaylist(from: url) }
            }
            .fileExporter(isPresented: isExporting, item: exportFile, contentTypes: [.m3uPlaylist],
                          defaultFilename: exportTarget.map { "\($0.name).m3u8" }) { finishExport($0) }
            .onChange(of: exportTarget?.playlistID) { prepareExport() }
            .alert("Playlist", isPresented: isShowingMessage, presenting: message) { _ in
                Button("OK") {}
            } message: { Text($0) }
    }

    private var isExporting: Binding<Bool> {
        Binding(get: { exportFile != nil },
                set: { if !$0 { exportFile = nil; exportTarget = nil } })
    }

    private var isShowingMessage: Binding<Bool> {
        Binding(get: { message != nil }, set: { if !$0 { message = nil } })
    }

    private func importPlaylist(from url: URL) {
        let isScoped = url.startAccessingSecurityScopedResource()
        defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let paths = M3UPlaylistParser.paths(in: try M3UPlaylistParser.read(url))
            let result = PlaylistImporter.match(paths, in: tracks)
            message = result.summary
            guard !result.trackPaths.isEmpty else { return }
            let playlist = LibraryPlaylist(name: url.deletingPathExtension().lastPathComponent,
                                           trackPaths: result.trackPaths)
            playlist.sortIndex = LibraryPlaylist.nextSortIndex(after: playlists)
            context.insert(playlist)
            selection = playlist.playlistID
        } catch {
            message = error.localizedDescription
        }
    }

    /// Absolute paths go in first, since the destination isn't known until the file is saved.
    private func prepareExport() {
        guard let exportTarget else { return }
        exportEntries = PlaylistEntry.entries(of: exportTarget, in: tracks)
        exportFile = M3UPlaylistFile(contents: PlaylistExporter.contents(of: exportEntries, relativeTo: nil))
    }

    /// Rewrites the saved file with paths relative to its folder.
    private func finishExport(_ result: Result<URL, any Error>) {
        do {
            let url = try result.get()
            let contents = PlaylistExporter.contents(of: exportEntries, relativeTo: url.deletingLastPathComponent())
            try contents.write(to: url, atomically: true, encoding: .utf8)
        } catch let error as CocoaError where error.code == .userCancelled {
            return
        } catch {
            message = error.localizedDescription
        }
    }
}

extension View {
    func playlistTransfer(isImporting: Binding<Bool>, exportTarget: Binding<LibraryPlaylist?>,
                          selection: Binding<UUID?>) -> some View {
        modifier(PlaylistTransferModifier(isImporting: isImporting, exportTarget: exportTarget,
                                          selection: selection))
    }
}
