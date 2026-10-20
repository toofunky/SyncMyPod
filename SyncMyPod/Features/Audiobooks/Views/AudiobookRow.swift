import SwiftData
import SwiftUI

struct AudiobookRow: View {
    let book: Audiobook

    private static let artworkSize: CGFloat = 40

    var body: some View {
        HStack {
            AudiobookArtworkView(book: book, size: Self.artworkSize)
            VStack(alignment: .leading) {
                Text(book.title)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
    }

    private var subtitle: String {
        book.author.isEmpty ? book.progressText : "\(book.author) · \(book.progressText)"
    }
}

#if DEBUG
#Preview {
    List {
        AudiobookRow(book: .preview)
    }
    .modelContainer(.preview)
}
#endif
