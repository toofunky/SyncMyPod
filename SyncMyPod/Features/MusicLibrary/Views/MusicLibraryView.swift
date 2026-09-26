import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct MusicLibraryView: View {
    private static let tagEditorMinWidth = 260.0
    private static let tagEditorIdealWidth = 300.0
    private static let tagEditorMaxWidth = 420.0

    @Environment(\.modelContext) private var context
    @Environment(IPodMountWatcher.self) private var watcher
    @Query private var folders: [LibraryFolder]
    @Query private var tracks: [LibraryTrack]
    @State private var model = MusicLibraryModel()
    @Environment(IPodSyncModel.self) private var syncModel
    @State private var isChoosingFolder = false
    @State private var isShowingTagEditor = false
    @State private var selection = Set<LibraryTrack.ID>()
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.system
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content
            .inspector(isPresented: $isShowingTagEditor) {
                TagEditorView(tracks: selectedTracks, isLocked: model.isScanning || syncModel.isSyncing)
                    .inspectorColumnWidth(min: Self.tagEditorMinWidth, ideal: Self.tagEditorIdealWidth,
                                          max: Self.tagEditorMaxWidth)
            }
            .toolbar { toolbarContent }
            .fileImporter(isPresented: $isChoosingFolder, allowedContentTypes: [.folder]) { result in
                if case .success(let url) = result { model.chooseFolder(url, in: context) }
            }
            .syncProgressSheet()
    }

    private var selectedTracks: [LibraryTrack] {
        tracks.filter { selection.contains($0.id) }
    }

    private var addToIPod: (([LibraryTrack]) -> Void)? {
        guard let device = watcher.connectedDevice, !syncModel.isSyncing else { return nil }
        return { tracks in
            let preserves = IPodSyncSettings.settings(for: device.id, in: context).preservesAlbumArtist
            syncModel.sync(tracks.map { $0.syncRequest(preservingAlbumArtist: preserves) }, to: device)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let folder = folders.first {
            VStack(alignment: .leading, spacing: 0) {
                LibraryScanStatusView(folderPath: folder.path, trackCount: tracks.count,
                                      lastScanDate: folder.lastScanDate, state: model.state,
                                      onCancel: model.cancelScan)
                LibraryTrackTableView(tracks: tracks, selection: $selection, addToIPod: addToIPod)
            }
        } else {
            ContentUnavailableView {
                Label("No Music Library", systemImage: "music.note.house")
            } description: {
                Text("Choose the folder that contains your AAC, Apple Lossless or MP3 music files.")
            } actions: {
                Button("Choose Folder…") { isChoosingFolder = true }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            if syncModel.isSyncing {
                ProgressView()
                    .controlSize(.small)
            }
            Button("Choose Folder…", systemImage: "folder.badge.plus") { isChoosingFolder = true }
                .disabled(model.isScanning)
            Button("Rescan", systemImage: "arrow.clockwise") { model.rescan(in: context) }
                .disabled(model.isScanning || folders.isEmpty)
            Button(AppAppearance.toggleTitle(for: colorScheme),
                   systemImage: AppAppearance.toggleSymbolName(for: colorScheme)) {
                appearance = AppAppearance.toggled(from: colorScheme)
            }
            Button("Tag Editor", systemImage: "sidebar.trailing") { isShowingTagEditor.toggle() }
                .disabled(folders.isEmpty)
        }
    }
}

#if DEBUG
#Preview("Library") {
    MusicLibraryView()
        .environment(IPodMountWatcher.preview(connectedDevice: .preview))
        .environment(IPodSyncModel())
        .modelContainer(.preview)
}

#Preview("Empty") {
    MusicLibraryView()
        .environment(IPodMountWatcher.preview())
        .environment(IPodSyncModel())
        .modelContainer(.emptyPreview)
}
#endif
