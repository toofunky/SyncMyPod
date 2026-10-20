import AppKit
import SwiftData
import SwiftUI

/// Chooses the folder audiobooks are scanned from.
struct AudiobookSettingsView: View {
    @Environment(AudiobookFolder.self) private var folder
    @State private var isChoosing = false

    var body: some View {
        Form {
            Section {
                LabeledContent("Audiobook Folder") {
                    folderControls
                }
            } footer: {
                Text("Each folder of audio files inside this one is a book, and so is each .m4b file. "
                     + "Choose a folder outside your music and podcast folders.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .audiobookFolderChooser(isPresented: $isChoosing)
    }

    private var folderControls: some View {
        HStack {
            Text(folder.path ?? "Not Chosen")
                .foregroundStyle(folder.url == nil ? .secondary : .primary)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(folder.path ?? "")
            if let url = folder.url {
                Button("Show in Finder", systemImage: "folder") { NSWorkspace.shared.activateFileViewerSelecting([url]) }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
            }
            Button("Choose…") { isChoosing = true }
        }
    }
}

#if DEBUG
#Preview {
    AudiobookSettingsView()
        .environment(AudiobookFolder.preview)
        .environment(PodcastFolder.preview)
        .modelContainer(.preview)
}
#endif
