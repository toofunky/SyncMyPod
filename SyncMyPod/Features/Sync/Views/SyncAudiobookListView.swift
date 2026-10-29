import SwiftUI

/// The books in the audiobook folder; choosing one syncs all of its files.
struct SyncAudiobookListView: View {
    let audiobooks: [SyncAudiobookSnapshot]
    @Binding var selection: Set<String>

    var body: some View {
        if audiobooks.isEmpty {
            ContentUnavailableView("No Audiobooks", systemImage: "book.closed",
                                   description: Text("Choose an audiobook folder in Audiobooks to sync its books."))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(audiobooks, id: \.key) { book in
                Toggle(isOn: $selection.contains(book.key)) {
                    SyncRowLabel(title: book.title, systemImage: "book.closed", detail: Self.detail(for: book))
                }
            }
            .toggleStyle(.checkbox)
        }
    }

    private static func detail(for book: SyncAudiobookSnapshot) -> String {
        let count = book.files.count
        let files = "\(count) \(count == 1 ? "file" : "files") · \(book.byteCount.formatted(.byteCount(style: .file)))"
        return book.author.isEmpty ? files : "\(book.author) · \(files)"
    }
}

#Preview {
    @Previewable @State var selection: Set<String> = []
    let part = SyncRequest(sourceURL: URL(filePath: "/Audiobooks/Mary Shelley/Frankenstein/01.m4a"),
                               tags: TrackTags(title: "Letters 1–4", album: "Frankenstein",
                                                       fileSize: 38_000_000),
                               kind: .audiobook)
    SyncAudiobookListView(audiobooks: [
        SyncAudiobookSnapshot(key: "book", title: "Frankenstein", author: "Mary Shelley", files: [part])
    ], selection: $selection)
}
