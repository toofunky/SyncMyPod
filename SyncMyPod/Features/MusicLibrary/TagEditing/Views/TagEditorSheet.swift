import SwiftData
import SwiftUI

/// The tag editor as a dialog, so the selection can't change while tags are being edited.
struct TagEditorSheet: View {
    private static let minWidth = 420.0
    private static let minHeight = 560.0

    @Environment(\.dismiss) private var dismiss
    @Environment(\.isTagEditingLocked) private var isLocked
    @State private var model: TagEditorModel

    init(tracks: [LibraryTrack]) {
        _model = State(initialValue: TagEditorModel(tracks: tracks))
    }

    var body: some View {
        TagEditorForm(model: model, isLocked: isLocked, onClose: { dismiss() })
            .frame(minWidth: Self.minWidth, minHeight: Self.minHeight)
    }
}

#if DEBUG
#Preview("One Song") {
    TagEditorSheet(tracks: [LibraryTrack.previewTracks[0]])
        .modelContainer(.preview)
}

#Preview("Several Songs") {
    TagEditorSheet(tracks: LibraryTrack.previewTracks)
        .modelContainer(.preview)
}
#endif
