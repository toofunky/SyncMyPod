import SwiftData
import SwiftUI

/// Presents the lyrics editor and confirms removing a song's lyric file, for the song a menu picked.
struct LyricsEditingModifier: ViewModifier {
    @Binding var editing: LibraryTrack?
    @Binding var removing: LibraryTrack?

    @State private var errorMessage: String?

    func body(content: Content) -> some View {
        content
            .sheet(item: $editing) { LyricsEditorSheet(track: $0) }
            .confirmationDialog("Remove Lyrics?", isPresented: isConfirmingRemoval, presenting: removing) { track in
                Button("Remove Lyrics", role: .destructive) { Task { await remove(track) } }
            } message: { track in
                Text("The .lrc file beside “\(track.title)” is deleted.")
            }
            .alert("Couldn't Remove Lyrics", isPresented: isShowingError, presenting: errorMessage) { _ in
                Button("OK") {}
            } message: { message in
                Text(message)
            }
    }

    private var isConfirmingRemoval: Binding<Bool> {
        Binding(get: { removing != nil }, set: { if !$0 { removing = nil } })
    }

    private var isShowingError: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func remove(_ track: LibraryTrack) async {
        do {
            try await LyricsFile.remove(forSongAt: track.filePath)
            track.hasLyrics = false
            track.lyricsFileDate = nil
            try track.modelContext?.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#if DEBUG
#Preview {
    Text("Songs")
        .padding()
        .modifier(LyricsEditingModifier(editing: .constant(nil), removing: .constant(nil)))
}
#endif
