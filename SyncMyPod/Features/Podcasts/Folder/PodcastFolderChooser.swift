import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Picks the podcast download folder, refusing one that overlaps the music folder.
struct PodcastFolderChooser: ViewModifier {
    @Binding var isPresented: Bool
    var onChoose: (URL) -> Void = { _ in }

    @Environment(PodcastFolder.self) private var folder
    @Query private var libraryFolders: [LibraryFolder]
    @State private var errorMessage: String?

    func body(content: Content) -> some View {
        content
            .fileImporter(isPresented: $isPresented, allowedContentTypes: [.folder]) { result in
                if case .success(let url) = result { choose(url) }
            }
            .fileDialogMessage("Choose a folder for podcast downloads, outside your music folder.")
            .fileDialogConfirmationLabel("Choose")
            .alert("Couldn't Use That Folder", isPresented: isShowingError, presenting: errorMessage) { _ in
                Button("OK") {}
            } message: { message in
                Text(message)
            }
    }

    private var isShowingError: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func choose(_ url: URL) {
        do {
            try folder.choose(url, libraryFolderPaths: libraryFolders.map(\.path))
            onChoose(url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension View {
    func podcastFolderChooser(isPresented: Binding<Bool>, onChoose: @escaping (URL) -> Void = { _ in }) -> some View {
        modifier(PodcastFolderChooser(isPresented: isPresented, onChoose: onChoose))
    }
}

#if DEBUG
#Preview {
    Text("Podcasts")
        .padding()
        .podcastFolderChooser(isPresented: .constant(false))
        .environment(PodcastFolder.preview)
        .modelContainer(.preview)
}
#endif
