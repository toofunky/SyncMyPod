import SwiftData
import SwiftUI

/// A book's details above its files.
struct AudiobookDetailView: View {
    let book: Audiobook

    var body: some View {
        VStack(spacing: 0) {
            AudiobookHeaderView(book: book)
            Divider()
            AudiobookFileTable(book: book)
        }
    }
}

#if DEBUG
#Preview {
    AudiobookDetailView(book: .preview)
        .environment(MusicPlayerModel())
        .modelContainer(.preview)
        .frame(width: 720, height: 400)
}
#endif
