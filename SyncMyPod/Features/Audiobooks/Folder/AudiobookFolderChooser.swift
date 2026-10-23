import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Picks the audiobook folder, refusing one that overlaps the music or podcast folder.
struct AudiobookFolderChooser: ViewModifier {
    @Binding var isPresented: Bool
    var onChoose: (URL) -> Void = { _ in }

    @Environment(AudiobookFolder.self) private var folder
    @Environment(PodcastFolder.self) private var podcastFolder: PodcastFolder?
    @Query private var libraryFolders: [LibraryFolder]
    @State private var errorMessage: String?

    func body(content: Content) -> some View {
        content
            .fileImporter(isPresented: $isPresented, allowedContentTypes: [.folder]) { result in
                if case .success(let url) = result { choose(url) }
            }
            .fileDialogMessage("Choose the folder holding your audiobooks, outside your music and podcast folders.")
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
            try folder.choose(url, libraryFolderPaths: libraryFolders.map(\.path),
                              podcastFolderPath: podcastFolder?.path)
            onChoose(url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension View {
    func audiobookFolderChooser(isPresented: Binding<Bool>, onChoose: @escaping (URL) -> Void = { _ in }) -> some View {
        modifier(AudiobookFolderChooser(isPresented: isPresented, onChoose: onChoose))
    }
}

#if DEBUG
#Preview {
    Text("Audiobooks")
        .padding()
        .audiobookFolderChooser(isPresented: .constant(false))
        .environment(AudiobookFolder.preview)
        .environment(PodcastFolder.preview)
        .modelContainer(.preview)
}
#endif
