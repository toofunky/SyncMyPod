import AppKit
import SwiftData
import SwiftUI

/// Chooses the folder podcast episodes are downloaded into.
struct PodcastSettingsView: View {
    @Environment(PodcastFolder.self) private var folder
    @State private var isChoosing = false

    var body: some View {
        Form {
            Section {
                LabeledContent("Download Folder") {
                    folderControls
                }
            } footer: {
                Text("Each podcast gets its own folder inside this one. Choose a folder outside your music folder. "
                     + "Changing it only affects new downloads.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .podcastFolderChooser(isPresented: $isChoosing)
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
    PodcastSettingsView()
        .environment(PodcastFolder.preview)
        .modelContainer(.preview)
}
#endif
