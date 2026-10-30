import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Imports `.m3u`/`.m3u8` files as new playlists and exports playlists as `.m3u8`.
struct PlaylistTransferModifier: ViewModifier {
    @Bindable var model: PlaylistsModel
    @Binding var isImporting: Bool
    @Binding var exportTarget: LibraryPlaylist?
    @Binding var selection: UUID?

    @Environment(\.modelContext) private var context
    @Query private var tracks: [LibraryTrack]
    @Query(sort: LibraryPlaylist.sidebarOrder) private var playlists: [LibraryPlaylist]

    func body(content: Content) -> some View {
        content
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.m3uPlaylist]) { result in
                if case .success(let url) = result { importPlaylist(from: url) }
            }
            .fileExporter(isPresented: isExporting, item: model.exportFile, contentTypes: [.m3uPlaylist],
                          defaultFilename: exportTarget.map { "\($0.name).m3u8" }) { model.finishExport($0) }
            .onChange(of: exportTarget?.playlistID) {
                if let exportTarget { model.prepareExport(of: exportTarget, tracks: tracks) }
            }
            .alert("Playlist", isPresented: isShowingMessage, presenting: model.message) { _ in
                Button("OK") {}
            } message: { Text($0) }
    }

    private var isExporting: Binding<Bool> {
        Binding(get: { model.exportFile != nil },
                set: { if !$0 { model.exportFile = nil; exportTarget = nil } })
    }

    private var isShowingMessage: Binding<Bool> {
        Binding(get: { model.message != nil }, set: { if !$0 { model.message = nil } })
    }

    private func importPlaylist(from url: URL) {
        if let playlist = model.importPlaylist(from: url, tracks: tracks, after: playlists, context: context) {
            selection = playlist.playlistID
        }
    }
}

extension View {
    func playlistTransfer(model: PlaylistsModel, isImporting: Binding<Bool>,
                          exportTarget: Binding<LibraryPlaylist?>, selection: Binding<UUID?>) -> some View {
        modifier(PlaylistTransferModifier(model: model, isImporting: isImporting, exportTarget: exportTarget,
                                          selection: selection))
    }
}
