import SwiftData
import SwiftUI

/// The album grid with the selected album's songs in a panel beside it.
///
/// The panel is part of the layout rather than an `inspector`: in a narrow window the floating inspector's width is
/// counted into the split view's minimum widths more than once, and AppKit's layout loops until it crashes.
struct AlbumBrowserView: View {
    private static let tracksWidth = 300.0

    let tracks: [LibraryTrack]
    var searchText = ""
    @Binding var selection: LibraryAlbum.ID?
    @Binding var isShowingTracks: Bool
    var showPlaylist: ((LibraryPlaylist) -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            AlbumGridView(tracks: tracks, searchText: searchText, selection: $selection)
            if isShowingTracks, selection != nil {
                Divider()
                AlbumTracksInspector(albumID: selection, showPlaylist: showPlaylist)
                    .frame(width: Self.tracksWidth)
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Album Tracks", systemImage: "sidebar.trailing") { isShowingTracks.toggle() }
                    .disabled(selection == nil)
            }
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: LibraryAlbum.ID? = LibraryAlbum.preview.id
    @Previewable @State var isShowingTracks = true
    AlbumBrowserView(tracks: LibraryTrack.previewTracks, selection: $selection, isShowingTracks: $isShowingTracks)
        .frame(width: 900, height: 500)
        .modelContainer(.preview)
}
#endif
