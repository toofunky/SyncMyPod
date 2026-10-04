import SwiftUI

/// Context menu items for adding, editing or removing one song's lyrics.
struct LyricsMenuItems: View {
    let track: LibraryTrack?
    let edit: (LibraryTrack) -> Void
    let remove: (LibraryTrack) -> Void

    var body: some View {
        Button(editTitle, systemImage: "text.page") {
            if let track { edit(track) }
        }
        .disabled(track == nil)
        Button("Remove Lyrics…", systemImage: "trash") {
            if let track { remove(track) }
        }
        .disabled(track?.hasLyrics != true)
    }

    private var editTitle: LocalizedStringKey {
        track?.hasLyrics == true ? "Edit Lyrics…" : "Add Lyrics…"
    }
}

#if DEBUG
#Preview {
    Menu("Lyrics") {
        LyricsMenuItems(track: LibraryTrack.previewTracks[0], edit: { _ in }, remove: { _ in })
    }
    .padding()
}
#endif
