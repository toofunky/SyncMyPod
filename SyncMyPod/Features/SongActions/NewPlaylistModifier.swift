import SwiftData
import SwiftUI

/// Asks for a name, then makes a playlist of the pending songs; an empty array makes an empty playlist.
struct NewPlaylistModifier: ViewModifier {
    @Binding var tracks: [LibraryTrack]?
    var onCreate: (LibraryPlaylist) -> Void = { _ in }

    @Environment(\.modelContext) private var context
    @State private var name = LibraryPlaylist.untitledName

    func body(content: Content) -> some View {
        content
            .alert("New Playlist", isPresented: isPresented, presenting: tracks) { tracks in
                TextField("Playlist Name", text: $name)
                Button("Create") { create(with: tracks) }
                    .keyboardShortcut(.defaultAction)
                Button("Cancel", role: .cancel) {}
            }
            .onChange(of: tracks != nil) { _, isShowing in
                if isShowing { name = LibraryPlaylist.untitledName }
            }
    }

    private var isPresented: Binding<Bool> {
        Binding(get: { tracks != nil }, set: { if !$0 { tracks = nil } })
    }

    private func create(with tracks: [LibraryTrack]) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let playlist = LibraryPlaylist(name: trimmed.isEmpty ? LibraryPlaylist.untitledName : trimmed,
                                       trackPaths: tracks.map(\.filePath))
        context.insert(playlist)
        onCreate(playlist)
    }
}

#if DEBUG
#Preview {
    @Previewable @State var tracks: [LibraryTrack]? = []
    Button("New Playlist") { tracks = [] }
        .padding()
        .modifier(NewPlaylistModifier(tracks: $tracks))
        .modelContainer(.emptyPreview)
}
#endif
