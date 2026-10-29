import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct MusicLibraryView: View {
    let model: MusicLibraryModel
    var section = LibrarySection.songs
    @Binding var selection: Set<LibraryTrack.ID>
    @Binding var albumSelection: LibraryAlbum.ID?
    @Binding var artistSelection: LibraryArtist.ID?
    @Binding var isShowingAlbumTracks: Bool
    var showPlaylist: ((LibraryPlaylist) -> Void)?

    @Environment(\.modelContext) private var context
    @Environment(\.isSyncingDevice) private var isSyncingDevice
    @Query private var folders: [LibraryFolder]
    @Query private var tracks: [LibraryTrack]
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
                                  showPlaylist: showPlaylist)
        case .albums:
            AlbumBrowserView(tracks: tracks, searchText: searchText, selection: $albumSelection,
                             isShowingTracks: $isShowingAlbumTracks, showPlaylist: showPlaylist)
        case .artists:
            ArtistsView(tracks: tracks, searchText: searchText, selection: $artistSelection,
                        showPlaylist: showPlaylist)
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
            if isSyncingDevice {
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
                     artistSelection: .constant(nil), isShowingAlbumTracks: .constant(false))
        .environment(\.libraryAddTargets, LibraryAddTarget.previews)
        .modelContainer(.preview)
}

#Preview("Albums") {
    @Previewable @State var albumSelection: LibraryAlbum.ID?
    @Previewable @State var isShowingAlbumTracks = true
    MusicLibraryView(model: MusicLibraryModel(), section: .albums, selection: .constant([]),
                     albumSelection: $albumSelection, artistSelection: .constant(nil),
                     isShowingAlbumTracks: $isShowingAlbumTracks)
        .environment(\.libraryAddTargets, LibraryAddTarget.previews)
        .modelContainer(.preview)
}

#Preview("Empty") {
    @Previewable @State var selection = Set<LibraryTrack.ID>()
    MusicLibraryView(model: MusicLibraryModel(), selection: $selection, albumSelection: .constant(nil),
                     artistSelection: .constant(nil), isShowingAlbumTracks: .constant(false))
        .modelContainer(.emptyPreview)
}
#endif
