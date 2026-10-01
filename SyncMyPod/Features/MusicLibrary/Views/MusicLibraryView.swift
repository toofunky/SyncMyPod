import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct MusicLibraryView: View {
    let model: MusicLibraryModel
    @Binding var selection: Set<LibraryTrack.ID>
    var showPlaylist: ((LibraryPlaylist) -> Void)?

    @Environment(\.modelContext) private var context
    @Environment(IPodMountWatcher.self) private var watcher
    @Query private var folders: [LibraryFolder]
    @Query private var tracks: [LibraryTrack]
    @Environment(IPodSyncModel.self) private var syncModel
    @State private var isChoosingFolder = false
    @State private var searchText = ""
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.system
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content
            .toolbar { toolbarContent }
            .fileImporter(isPresented: $isChoosingFolder, allowedContentTypes: [.folder]) { result in
                if case .success(let url) = result { model.chooseFolder(url, in: context) }
            }
            .syncProgressSheet()
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
                LibraryTrackTableView(tracks: tracks, selection: $selection, searchText: searchText,
                                      addToIPod: addToIPod, showPlaylist: showPlaylist)
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
        ToolbarItem {
            ToolbarSearchField(prompt: "Search Library", text: $searchText)
                .disabled(folders.isEmpty)
        }
//        ToolbarSpacer(.fixed)
        ToolbarItemGroup {
            Button("Choose Folder…", systemImage: "folder.badge.plus") { isChoosingFolder = true }
                .disabled(model.isScanning)
            Button("Rescan", systemImage: "arrow.clockwise") { model.rescan(in: context) }
                .disabled(model.isScanning || folders.isEmpty)
            Button(AppAppearance.toggleTitle(for: colorScheme),
                   systemImage: AppAppearance.toggleSymbolName(for: colorScheme)) {
                appearance = AppAppearance.toggled(from: colorScheme)
            }
            if syncModel.isSyncing {
                ProgressView()
                    .controlSize(.small)
            }
        }
//            ToolbarSpacer(.flexible)
//            ToolbarItem(placement: .primaryAction) {
//                trailingButton
                //            Button("Tag Editor", systemImage: "sidebar.trailing") { isShowingTagEditor.toggle() }
                //                .disabled(folders.isEmpty)
//            }
    }
}

#if DEBUG
#Preview("Library") {
    @Previewable @State var selection = Set<LibraryTrack.ID>()
    MusicLibraryView(model: MusicLibraryModel(), selection: $selection)
        .environment(IPodMountWatcher.preview(connectedDevice: .preview))
        .environment(IPodSyncModel())
        .modelContainer(.preview)
}

#Preview("Empty") {
    @Previewable @State var selection = Set<LibraryTrack.ID>()
    MusicLibraryView(model: MusicLibraryModel(), selection: $selection)
        .environment(IPodMountWatcher.preview())
        .environment(IPodSyncModel())
        .modelContainer(.emptyPreview)
}
#endif
