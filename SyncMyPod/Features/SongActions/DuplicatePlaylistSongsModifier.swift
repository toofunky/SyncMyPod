import SwiftData
import SwiftUI

/// Asks whether to add songs that are already in the playlist they're being added to.
struct DuplicatePlaylistSongsModifier: ViewModifier {
    @Binding var addition: PlaylistAddition?

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: isPresented, presenting: addition) { addition in
                Button("Add Anyway") { addition.addAll() }
                    .keyboardShortcut(.defaultAction)
                if !addition.newTracks.isEmpty {
                    Button("Skip Duplicates") { addition.addNewTracks() }
                }
                Button("Cancel", role: .cancel) {}
            } message: { addition in
                Text(message(for: addition))
            }
    }

    private var isPresented: Binding<Bool> {
        Binding(get: { addition != nil }, set: { if !$0 { addition = nil } })
    }

    private var title: String {
        guard let addition else { return "" }
        let duplicates = addition.duplicates
        if duplicates.count == 1, let track = duplicates.first {
            return "“\(track.title)” is already in “\(addition.playlist.name)”."
        }
        return "\(duplicates.count) songs are already in “\(addition.playlist.name)”."
    }

    private func message(for addition: PlaylistAddition) -> String {
        addition.duplicates.count == 1
            ? "Do you want to add it again?"
            : "Do you want to add them again?"
    }
}

#if DEBUG
#Preview {
    @Previewable @State var addition: PlaylistAddition?
    Button("Add to Playlist") {
        addition = PlaylistAddition(tracks: LibraryTrack.previewTracks, playlist: .preview)
    }
    .padding()
    .modifier(DuplicatePlaylistSongsModifier(addition: $addition))
    .modelContainer(.emptyPreview)
}
#endif
