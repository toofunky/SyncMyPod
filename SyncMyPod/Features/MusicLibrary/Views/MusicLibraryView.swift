import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct MusicLibraryView: View {
    let model: MusicLibraryModel
    var section = LibrarySection.songs
    @Binding var selection: Set<LibraryTrack.ID>
    @Binding var albumSelection: LibraryAlbum.ID?
    @Binding var artistSelection: LibraryArtist.ID?
    var showPlaylist: ((LibraryPlaylist) -> Void)?

    @Environment(\.modelContext) private var context
    @Environment(DeviceMountWatcher.self) private var watcher
    @Query private var folders: [LibraryFolder]
    @Query private var tracks: [LibraryTrack]
    @Environment(DeviceSyncModel.self) private var syncModel
    @State private var isChoosingFolder = false
    @State private var searchText = ""
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.system
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content
            .toolbar { toolbarContent }
            .modifier(LibraryFolderChoiceModifier(isChoosingFolder: $isChoosingFolder, currentFolder: folders.first) {
                model.chooseFolder($0, in: context)
            })
            .syncProgressSheet()
    }

    private var addTargets: [ConnectedDevice] {
        syncModel.isSyncing ? [] : watcher.connectedDevices
    }

    private var addToDevice: ((ConnectedDevice, [LibraryTrack]) -> Void)? {
        guard !addTargets.isEmpty else { return nil }
        return { device, tracks in
            syncModel.sync(syncRequests(for: tracks, to: device), to: device)
        }
    }

    private func syncRequests(for tracks: [LibraryTrack], to device: ConnectedDevice) -> [IPodSyncRequest] {
        switch device {
        case .iPod(let iPod):
            let settings = IPodSyncSettings.settings(for: device.id, in: context)
            let embedsLyrics = settings.syncsLyricsSidecars && iPod.showsLyrics
            return tracks.filter(\.codec.syncsToIPod).map {
                $0.syncRequest(preservingAlbumArtist: settings.preservesAlbumArtist,
                               embeddingLyricsSidecar: embedsLyrics)
            }
        case .audioPlayer(let player):
            return tracks.map { $0.syncRequest(preservingAlbumArtist: player.config.preserveAlbumArtist) }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let folder = folders.first {
            VStack(alignment: .leading, spacing: 0) {
                LibraryScanStatusView(folderPath: folder.path, trackCount: tracks.count,
                                      lastScanDate: folder.lastScanDate, state: model.state,
                                      onCancel: model.cancelScan)
                sectionContent
            }
        } else {
            ContentUnavailableView {
                Label("No Music Library", systemImage: "music.note.house")
            } description: {
                Text("Choose the folder that contains your AAC, Apple Lossless, MP3, FLAC, AIFF or WAV music files.")
            } actions: {
                Button("Choose Folder…") { isChoosingFolder = true }
            }
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch section {
        case .songs:
            LibraryTrackTableView(tracks: tracks, selection: $selection, searchText: searchText,
                                  addTargets: addTargets, addToDevice: addToDevice, showPlaylist: showPlaylist)
        case .albums:
            AlbumGridView(tracks: tracks, searchText: searchText, selection: $albumSelection)
        case .artists:
            ArtistsView(tracks: tracks, searchText: searchText, selection: $artistSelection)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem {
            ToolbarSearchField(prompt: "Search Library", text: $searchText)
                .disabled(folders.isEmpty)
        }
        ToolbarSpacer(.fixed)
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
#Preview("Songs") {
    @Previewable @State var selection = Set<LibraryTrack.ID>()
    MusicLibraryView(model: MusicLibraryModel(), selection: $selection, albumSelection: .constant(nil),
                     artistSelection: .constant(nil))
        .environment(DeviceMountWatcher.preview(connectedDevices: [.iPod(.preview)]))
        .environment(DeviceSyncModel())
        .modelContainer(.preview)
}

#Preview("Albums") {
    @Previewable @State var albumSelection: LibraryAlbum.ID?
    MusicLibraryView(model: MusicLibraryModel(), section: .albums, selection: .constant([]),
                     albumSelection: $albumSelection, artistSelection: .constant(nil))
        .environment(DeviceMountWatcher.preview(connectedDevices: [.iPod(.preview)]))
        .environment(DeviceSyncModel())
        .modelContainer(.preview)
}

#Preview("Empty") {
    @Previewable @State var selection = Set<LibraryTrack.ID>()
    MusicLibraryView(model: MusicLibraryModel(), selection: $selection, albumSelection: .constant(nil),
                     artistSelection: .constant(nil))
        .environment(DeviceMountWatcher.preview())
        .environment(DeviceSyncModel())
        .modelContainer(.emptyPreview)
}
#endif
