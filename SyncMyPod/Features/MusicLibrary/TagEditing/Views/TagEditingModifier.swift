import SwiftData
import SwiftUI

/// Opens the tag editor dialog for the pending songs, and clears them when it closes.
struct TagEditingModifier: ViewModifier {
    @Binding var tracks: [LibraryTrack]?

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: isPresented) {
                if let tracks { TagEditorSheet(tracks: tracks) }
            }
    }

    private var isPresented: Binding<Bool> {
        Binding(get: { tracks != nil }, set: { if !$0 { tracks = nil } })
    }
}

#if DEBUG
#Preview {
    @Previewable @State var tracks: [LibraryTrack]?
    Button("Edit Tags…") { tracks = LibraryTrack.previewTracks }
        .padding()
        .modifier(TagEditingModifier(tracks: $tracks))
        .modelContainer(.preview)
}
#endif
