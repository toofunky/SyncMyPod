import AppKit
import SwiftData
import SwiftUI

/// A book's files in listening order, marking the one where listening stopped.
struct AudiobookFileTable: View {
    let book: Audiobook

    @State private var selection = Set<AudiobookFile.ID>()

    var body: some View {
        let files = book.sortedFiles
        Table(files, selection: $selection) {
            TableColumn("#") { file in
                position(of: file, in: files)
            }
            .width(min: 30, ideal: 40, max: 60)
            TableColumn("Title") { file in
                Text(file.title)
                    .help(file.fileName)
            }
            .width(min: 160, ideal: 320)
            TableColumn("Duration") { file in
                Text(Audiobook.formatted(file.duration))
            }
            .width(min: 60, ideal: 90)
            TableColumn("Size") { file in
                Text(file.fileSize.formatted(.byteCount(style: .file)))
            }
            .width(min: 60, ideal: 70)
        }
        .contextMenu(forSelectionType: AudiobookFile.ID.self) { ids in
            Button("Show in Finder", systemImage: "folder") {
                NSWorkspace.shared.activateFileViewerSelecting(files.filter { ids.contains($0.id) }.map(\.fileURL))
            }
            .disabled(ids.isEmpty)
        }
    }

    @ViewBuilder
    private func position(of file: AudiobookFile, in files: [AudiobookFile]) -> some View {
        if file.filePath == book.currentFilePath {
            Image(systemName: "bookmark.fill")
                .foregroundStyle(.tint)
                .help("Listening stopped here")
                .accessibilityLabel("Listening stopped here")
        } else {
            Text("\((files.firstIndex { $0.id == file.id } ?? 0) + 1)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}

#if DEBUG
#Preview {
    AudiobookFileTable(book: .preview)
        .modelContainer(.preview)
        .frame(width: 600, height: 240)
}
#endif
