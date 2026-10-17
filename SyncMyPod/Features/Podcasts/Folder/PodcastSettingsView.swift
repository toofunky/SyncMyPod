import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Chooses the folder podcast episodes are downloaded into.
struct PodcastSettingsView: View {
    @Environment(PodcastFolder.self) private var folder
    @Query private var libraryFolders: [LibraryFolder]
    @State private var isChoosing = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                LabeledContent("Download Folder") {
                    folderControls
                }
            } footer: {
                Text("Each podcast gets its own folder inside this one. Choose a folder outside your music folder.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .fileImporter(isPresented: $isChoosing, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result { choose(url) }
        }
        .alert("Couldn't Use That Folder", isPresented: isShowingError, presenting: errorMessage) { _ in
            Button("OK") {}
        } message: { message in
            Text(message)
        }
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

    private var isShowingError: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func choose(_ url: URL) {
        do {
            try folder.choose(url, libraryFolderPaths: libraryFolders.map(\.path))
        } catch {
            errorMessage = error.localizedDescription
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
