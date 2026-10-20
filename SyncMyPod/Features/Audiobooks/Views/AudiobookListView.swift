import AppKit
import SwiftData
import SwiftUI

struct AudiobookListView: View {
    let books: [Audiobook]
    @Binding var selection: UUID?

    var body: some View {
        List(selection: $selection) {
            ForEach(books) { book in
                AudiobookRow(book: book)
                    .tag(book.bookID)
                    .contextMenu {
                        Button("Show in Finder", systemImage: "folder") {
                            NSWorkspace.shared.activateFileViewerSelecting([URL(filePath: book.folderPath)])
                        }
                    }
            }
        }
        .onAppear(perform: selectFirstIfNeeded)
        .onChange(of: books.map(\.bookID)) { selectFirstIfNeeded() }
    }

    private func selectFirstIfNeeded() {
        guard selection == nil || !books.contains(where: { $0.bookID == selection }) else { return }
        selection = books.first?.bookID
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: UUID?
    AudiobookListView(books: [.preview], selection: $selection)
        .modelContainer(.preview)
        .frame(width: 260, height: 300)
}
#endif
