import SwiftData
import SwiftUI

struct AudiobookHeaderView: View {
    let book: Audiobook

    private static let artworkSize: CGFloat = 96

    var body: some View {
        HStack(alignment: .top) {
            AudiobookArtworkView(book: book, size: Self.artworkSize)
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.title2.bold())
                    .lineLimit(2)
                if !book.author.isEmpty {
                    Text(book.author)
                        .foregroundStyle(.secondary)
                }
                details
            }
            Spacer(minLength: 0)
        }
        .padding()
    }

    private var details: some View {
        HStack(spacing: 4) {
            Text("^[\(book.files.count) file](inflect: true)")
            Text("·")
            Text(book.progressText)
            Text("·")
            Text(book.byteCount.formatted(.byteCount(style: .file)))
        }
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
}

#if DEBUG
#Preview {
    AudiobookHeaderView(book: .preview)
        .modelContainer(.preview)
        .frame(width: 600)
}
#endif
