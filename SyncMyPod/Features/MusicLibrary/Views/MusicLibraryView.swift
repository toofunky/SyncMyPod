import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct MusicLibraryView: View {
    @Environment(\.modelContext) private var context
    @Query private var folders: [LibraryFolder]
    @Query private var tracks: [LibraryTrack]
    @State private var model = MusicLibraryModel()
    @State private var isChoosingFolder = false

    var body: some View {
        content
            .toolbar { toolbarContent }
            .fileImporter(isPresented: $isChoosingFolder, allowedContentTypes: [.folder]) { result in
                if case .success(let url) = result { model.chooseFolder(url, in: context) }
            }
    }

    @ViewBuilder
    private var content: some View {
        if let folder = folders.first {
            VStack(alignment: .leading, spacing: 0) {
                LibraryScanStatusView(folderPath: folder.path, trackCount: tracks.count,
                                      lastScanDate: folder.lastScanDate, state: model.state,
                                      onCancel: model.cancelScan)
                LibraryTrackTableView(tracks: tracks)
            }
        } else {
            ContentUnavailableView {
                Label("No Music Library", systemImage: "music.note.house")
            } description: {
                Text("Choose the folder that contains your AAC music files.")
            } actions: {
                Button("Choose Folder…") { isChoosingFolder = true }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            Button("Choose Folder…", systemImage: "folder.badge.plus") { isChoosingFolder = true }
                .disabled(model.isScanning)
            Button("Rescan", systemImage: "arrow.clockwise") { model.rescan(in: context) }
                .disabled(model.isScanning || folders.isEmpty)
        }
    }
}

#Preview("Library") {
    MusicLibraryView()
        .modelContainer(.preview)
}

#Preview("Empty") {
    MusicLibraryView()
        .modelContainer(.emptyPreview)
}
