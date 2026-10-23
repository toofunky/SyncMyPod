import AppKit
import SwiftData
import SwiftUI

/// The book list's context menu.
struct AudiobookMenu: View {
    let book: Audiobook

    @Environment(MusicPlayerModel.self) private var player: MusicPlayerModel?

    var body: some View {
        Button(book.isStarted ? "Resume" : "Play", systemImage: "play") { player?.play(book) }
            .disabled(player == nil)
        Button("Play from Beginning", systemImage: "backward.end") {
            player?.play(book, from: book.sortedFiles.first)
            player?.seek(to: 0)
        }
        .disabled(player == nil)
        Divider()
        Button("Show in Finder", systemImage: "folder") {
            NSWorkspace.shared.activateFileViewerSelecting([URL(filePath: book.folderPath)])
        }
    }
}

#if DEBUG
#Preview {
    Menu("Book") {
        AudiobookMenu(book: .preview)
    }
    .padding()
    .environment(MusicPlayerModel())
    .modelContainer(.preview)
}
#endif
