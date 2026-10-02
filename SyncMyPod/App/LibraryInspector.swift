import SwiftData
import SwiftUI

/// The window's trailing column: the tag editor for Songs, or the selected album's songs for Albums.
struct LibraryInspector: View {
    let section: LibrarySection?
    let trackSelection: Set<LibraryTrack.ID>
    let albumID: LibraryAlbum.ID?
    let isLocked: Bool
    @Binding var isShowingTagEditor: Bool
    @Binding var isShowingAlbum: Bool

    var body: some View {
        if section == .albums {
            AlbumTracksInspector(albumID: albumID, isShowing: $isShowingAlbum)
        } else {
            LibraryTagEditorInspector(selection: trackSelection, isLocked: isLocked, isShowing: $isShowingTagEditor)
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var isShowing = true
    LibraryInspector(section: .albums, trackSelection: [], albumID: LibraryAlbum.preview.id, isLocked: false,
                     isShowingTagEditor: $isShowing, isShowingAlbum: $isShowing)
        .modelContainer(.preview)
}
#endif
