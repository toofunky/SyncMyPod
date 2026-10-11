import SwiftData
import SwiftUI

/// The tag editor as a dialog, for song lists without the tag editor inspector.
struct TagEditorSheet: View {
    private static let minWidth = 420.0
    private static let minHeight = 560.0

    @Environment(\.dismiss) private var dismiss
    @Environment(\.isTagEditingLocked) private var isLocked
    @State private var model: TagEditorModel

    init(track: LibraryTrack) {
        _model = State(initialValue: TagEditorModel(tracks: [track]))
    }

    var body: some View {
        TagEditorForm(model: model, isLocked: isLocked, onClose: { dismiss() })
            .frame(minWidth: Self.minWidth, minHeight: Self.minHeight)
    }
}

#if DEBUG
#Preview {
    TagEditorSheet(track: LibraryTrack.previewTracks[0])
        .modelContainer(.preview)
}
#endif
