import AppKit
import SwiftData
import SwiftUI

/// Chooses the folder audiobooks are scanned from.
struct AudiobookSettingsView: View {
    @Environment(MediaFolders.self) private var mediaFolders
    @Query private var libraryFolders: [LibraryFolder]
    @State private var isChoosing = false

    private var folder: ManagedFolder { mediaFolders.audiobooks }

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
        .mediaFolderChooser(.audiobooks, isPresented: $isChoosing, musicFolderPath: libraryFolders.first?.path)
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
        .environment(MediaFolders.preview)
        .modelContainer(.preview)
}
#endif
