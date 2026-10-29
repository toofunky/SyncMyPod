import SwiftUI
import UniformTypeIdentifiers

/// Picks the podcast or audiobook folder, refusing one that overlaps the app's other folders.
struct MediaFolderChooser: ViewModifier {
    let kind: MediaFolderKind
    @Binding var isPresented: Bool
    let musicFolderPath: String?
    var onChoose: (URL) -> Void = { _ in }

    @Environment(MediaFolders.self) private var folders
    @State private var errorMessage: String?

    func body(content: Content) -> some View {
        content
            .fileImporter(isPresented: $isPresented, allowedContentTypes: [.folder]) { result in
                if case .success(let url) = result { choose(url) }
            }
            .fileDialogMessage(prompt)
            .fileDialogConfirmationLabel("Choose")
            .alert("Couldn't Use That Folder", isPresented: isShowingError, presenting: errorMessage) { _ in
                Button("OK") {}
            } message: { message in
                Text(message)
            }
    }

    private var prompt: String {
        switch kind {
        case .music: "Choose the folder that contains your music."
        case .podcasts: "Choose a folder for podcast downloads, outside your music and audiobook folders."
        case .audiobooks: "Choose the folder holding your audiobooks, outside your music and podcast folders."
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func choose(_ url: URL) {
        do {
            try folders.choose(url, as: kind, musicFolderPath: musicFolderPath)
            onChoose(url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension View {
    func mediaFolderChooser(_ kind: MediaFolderKind, isPresented: Binding<Bool>, musicFolderPath: String?,
                            onChoose: @escaping (URL) -> Void = { _ in }) -> some View {
        modifier(MediaFolderChooser(kind: kind, isPresented: isPresented, musicFolderPath: musicFolderPath,
                                    onChoose: onChoose))
    }
}

#if DEBUG
#Preview {
    Text("Podcasts")
        .padding()
        .mediaFolderChooser(.podcasts, isPresented: .constant(false), musicFolderPath: nil)
        .environment(MediaFolders.preview)
}
#endif
