import SwiftData
import SwiftUI

struct TagEditorView: View {
    let tracks: [LibraryTrack]
    /// Set while a scan or sync is reading the files, when saving would race it.
    var isLocked = false

    @State private var model: TagEditorModel?

    var body: some View {
        Group {
            if let model {
                TagEditorForm(model: model, isLocked: isLocked)
                    .id(ObjectIdentifier(model))
            } else {
                ContentUnavailableView("No Selection", systemImage: "music.note",
                                       description: Text("Select songs in the library to edit their tags."))
            }
        }
        .onChange(of: tracks.map(\.persistentModelID), initial: true) {
            model = tracks.isEmpty ? nil : TagEditorModel(tracks: tracks)
        }
    }
}

#Preview("Selection") {
    TagEditorView(tracks: LibraryTrack.previewTracks)
        .modelContainer(.preview)
}

#Preview("No Selection") {
    TagEditorView(tracks: [])
        .modelContainer(.emptyPreview)
}
