import SwiftData
import SwiftUI

/// The books in the audiobook folder. Double-clicking one carries on from where it was left.
struct AudiobookListView: View {
    let books: [Audiobook]
    @Binding var selection: UUID?

    @Environment(MusicPlayerModel.self) private var player: MusicPlayerModel?

    var body: some View {
        List(selection: $selection) {
            ForEach(books) { book in
                AudiobookRow(book: book)
                    .tag(book.bookID)
            }
        }
        .contextMenu(forSelectionType: UUID.self) { ids in
            if let book = book(in: ids) { AudiobookMenu(book: book) }
        } primaryAction: { ids in
            if let book = book(in: ids) { player?.play(book) }
        }
        .onAppear(perform: selectFirstIfNeeded)
        .onChange(of: books.map(\.bookID)) { selectFirstIfNeeded() }
    }

    private func book(in ids: Set<UUID>) -> Audiobook? {
        books.first { ids.contains($0.bookID) }
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
        .environment(MusicPlayerModel())
        .modelContainer(.preview)
        .frame(width: 260, height: 300)
}
#endif
