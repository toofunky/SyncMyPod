import SwiftUI
import UniformTypeIdentifiers

/// Picks a music folder, warning before replacing an already-scanned library with a different folder.
struct LibraryFolderChoiceModifier: ViewModifier {
    @Binding var isChoosingFolder: Bool
    let currentFolder: LibraryFolder?
    let onChoose: (URL) -> Void

    @State private var pendingURL: URL?

    func body(content: Content) -> some View {
        content
            .fileImporter(isPresented: $isChoosingFolder, allowedContentTypes: [.folder]) { result in
                if case .success(let url) = result { choose(url) }
            }
            .confirmationDialog("Switch Music Library?", isPresented: isConfirmingSwitch, presenting: pendingURL) { url in
                Button("Switch Library", role: .destructive) { onChoose(url) }
            } message: { url in
                Text(switchMessage(to: url))
            }
    }

    private var isConfirmingSwitch: Binding<Bool> {
        Binding(get: { pendingURL != nil }, set: { if !$0 { pendingURL = nil } })
    }

    private func switchMessage(to url: URL) -> String {
        let current = currentFolder?.path ?? ""
        let new = url.path(percentEncoded: false)
        return "Playlists refer to songs by their location in “\(current)”. Scanning “\(new)” removes songs "
            + "that aren't in it from the library, and playlists containing them may be corrupted."
    }

    private func choose(_ url: URL) {
        if replacesScannedLibrary(with: url) { pendingURL = url } else { onChoose(url) }
    }

    private func replacesScannedLibrary(with url: URL) -> Bool {
        guard let currentFolder, currentFolder.lastScanDate != nil else { return false }
        return Self.normalized(currentFolder.path) != Self.normalized(url.path(percentEncoded: false))
    }

    private static func normalized(_ path: String) -> String {
        URL(filePath: path, directoryHint: .isDirectory).standardizedFileURL.path(percentEncoded: false)
    }
}

#if DEBUG
#Preview {
    Text("Library")
        .padding()
        .modifier(LibraryFolderChoiceModifier(isChoosingFolder: .constant(false), currentFolder: .preview,
                                              onChoose: { _ in }))
}
#endif
