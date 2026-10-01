import SwiftData
import SwiftUI

struct LibraryTagEditorInspector: View {
    private static let minWidth = 260.0
    private static let idealWidth = 300.0
    private static let maxWidth = 420.0

    let selection: Set<LibraryTrack.ID>
    let isLocked: Bool
    @Binding var isShowing: Bool

    @Query private var folders: [LibraryFolder]
    @Query private var tracks: [LibraryTrack]

    var body: some View {
        TagEditorView(tracks: tracks.filter { selection.contains($0.id) }, isLocked: isLocked)
            .inspectorColumnWidth(min: Self.minWidth, ideal: Self.idealWidth, max: Self.maxWidth)
            .toolbar {
                Spacer()
                Button("Tag Editor", systemImage: "sidebar.trailing") { isShowing.toggle() }
                    .disabled(folders.isEmpty)
            }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var isShowing = true
    LibraryTagEditorInspector(selection: [], isLocked: false, isShowing: $isShowing)
        .modelContainer(.preview)
}
#endif
