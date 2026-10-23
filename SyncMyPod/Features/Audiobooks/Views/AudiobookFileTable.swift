import AppKit
import SwiftData
import SwiftUI

/// A book's files in listening order, marking the one playing or where listening stopped.
/// Double-clicking a file plays the book from it.
struct AudiobookFileTable: View {
    let book: Audiobook

    @Environment(MusicPlayerModel.self) private var player: MusicPlayerModel?
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
            menu(for: files.filter { ids.contains($0.id) })
        } primaryAction: { ids in
            if let file = files.first(where: { ids.contains($0.id) }) { player?.play(book, from: file) }
        }
    }

    @ViewBuilder
    private func menu(for selected: [AudiobookFile]) -> some View {
        Button("Play from Here", systemImage: "play") {
            if let file = selected.first { player?.play(book, from: file) }
        }
        .disabled(selected.isEmpty || player == nil)
        Divider()
        Button("Show in Finder", systemImage: "folder") {
            NSWorkspace.shared.activateFileViewerSelecting(selected.map(\.fileURL))
        }
        .disabled(selected.isEmpty)
    }

    @ViewBuilder
    private func position(of file: AudiobookFile, in files: [AudiobookFile]) -> some View {
        if let player, player.isCurrent(file) {
            marker(player.isPlaying ? "speaker.wave.2.fill" : "speaker.fill",
                   label: player.isPlaying ? "Now Playing" : "Paused")
        } else if file.filePath == book.currentFilePath {
            marker("bookmark.fill", label: "Listening stopped here")
        } else {
            Text("\((files.firstIndex { $0.id == file.id } ?? 0) + 1)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    private func marker(_ systemImage: String, label: String) -> some View {
        Image(systemName: systemImage)
            .foregroundStyle(.tint)
            .help(label)
            .accessibilityLabel(label)
    }
}

#if DEBUG
#Preview {
    AudiobookFileTable(book: .preview)
        .environment(MusicPlayerModel())
        .modelContainer(.preview)
        .frame(width: 600, height: 240)
}
#endif
