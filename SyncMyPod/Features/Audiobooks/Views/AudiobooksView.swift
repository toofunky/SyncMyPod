import SwiftData
import SwiftUI

/// The books in the audiobook folder beside the selected one's files. Scans the folder the first time it's shown.
struct AudiobooksView: View {
    private static let listWidthRange = 200.0...360.0
    private static let detailMinWidth = 360.0

    @Binding var selection: UUID?

    @Environment(AudiobooksModel.self) private var model
    @Environment(MediaFolders.self) private var mediaFolders
    @Query private var libraryFolders: [LibraryFolder]
    @Environment(MusicPlayerModel.self) private var player: MusicPlayerModel?
    @Environment(\.modelContext) private var context
    @Query(sort: Audiobook.titleOrder) private var books: [Audiobook]
    @AppStorage("audiobookListWidth") private var listWidth = 240.0
    @State private var isChoosingFolder = false

    private var folder: ManagedFolder { mediaFolders.audiobooks }

    var body: some View {
        VStack(spacing: 0) {
            if let path = folder.path {
                LibraryScanStatusView(folderPath: path, trackCount: books.count, lastScanDate: nil,
                                      state: model.state, onCancel: model.cancelScan, itemName: "book")
                Divider()
            }
            content
        }
        .toolbar { toolbarContent }
        .mediaFolderChooser(.audiobooks, isPresented: $isChoosingFolder, musicFolderPath: libraryFolders.first?.path)
        .task(id: folder.url) {
            if let url = folder.url { model.scanIfNeeded(url, in: context) }
        }
        .onChange(of: books.map(\.bookID)) { player?.stopAudiobook(missingFrom: books) }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            Button("Choose Folder…", systemImage: "folder.badge.plus") { isChoosingFolder = true }
                .disabled(model.isScanning)
            Button("Rescan", systemImage: "arrow.clockwise") {
                if let url = folder.url { model.rescan(url, in: context) }
            }
            .disabled(model.isScanning || folder.url == nil)
        }
    }

    @ViewBuilder
    private var content: some View {
        if folder.url == nil {
            ContentUnavailableView {
                Label("No Audiobook Folder", systemImage: "book.closed")
            } description: {
                Text("Choose the folder that holds your audiobooks. Each folder of audio files inside it is a book, "
                     + "and so is each .m4b file.")
            } actions: {
                Button("Choose Folder…") { isChoosingFolder = true }
            }
        } else if books.isEmpty {
            ContentUnavailableView("No Audiobooks", systemImage: "book.closed",
                                   description: Text(model.isScanning ? "Looking for books…"
                                                     : "The audiobook folder doesn't hold any audio files."))
        } else {
            // Not an HSplitView, which adds the floating sidebar's width to its panes' minimum widths.
            HStack(spacing: 0) {
                AudiobookListView(books: books, selection: $selection)
                    .frame(width: listWidth)
                ResizableDivider(width: $listWidth, range: Self.listWidthRange)
                detail
                    .frame(minWidth: Self.detailMinWidth, maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let book = books.first(where: { $0.bookID == selection }) {
            AudiobookDetailView(book: book)
                .id(book.bookID)
        } else {
            ContentUnavailableView("No Book Selected", systemImage: "book.closed",
                                   description: Text("Select a book to see its files."))
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: UUID? = Audiobook.preview.bookID
    AudiobooksView(selection: $selection)
        .environment(AudiobooksModel())
        .environment(MusicPlayerModel())
        .environment(MediaFolders.preview)
        .modelContainer(.preview)
}

#Preview("No Folder") {
    AudiobooksView(selection: .constant(nil))
        .environment(AudiobooksModel())
        .environment(MusicPlayerModel())
        .environment(MediaFolders.preview)
        .modelContainer(.emptyPreview)
}
#endif
