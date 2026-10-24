import SwiftData
import SwiftUI

struct ArtistsView: View {
    private static let listWidthRange = 160.0...320.0
    private static let detailMinWidth = 300.0

    let tracks: [LibraryTrack]
    var searchText = ""
    @Binding var selection: LibraryArtist.ID?
    var showPlaylist: ((LibraryPlaylist) -> Void)?

    @AppStorage("artistAlbumSortOrder") private var sortOrder = AlbumSortOrder.year
    @AppStorage("artistListWidth") private var listWidth = 220.0
    @State private var artists: [LibraryArtist] = []
    @State private var sections: [ArtistAlbumSection] = []

    var body: some View {
        // Not an HSplitView: inside the split view it adds the floating sidebar and inspector widths to its panes'
        // minimum widths, and the window can then never satisfy them, which crashes AppKit's layout.
        HStack(spacing: 0) {
            ArtistListView(artists: visibleArtists, selection: $selection)
                .frame(width: listWidth)
            ResizableDivider(width: $listWidth, range: Self.listWidthRange)
            detail
                .frame(minWidth: Self.detailMinWidth, maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: tracks, initial: true) { reloadArtists() }
        .onModelContextSave { reloadArtists() }
        .onChange(of: selection) { updateSections() }
        .onChange(of: sortOrder) { updateSections() }
    }

    private var visibleArtists: [LibraryArtist] {
        let query = TrackSearchQuery(searchText)
        return artists.filter { query.matches($0.name) }
    }

    @ViewBuilder
    private var detail: some View {
        if let selection, !sections.isEmpty {
            ArtistAlbumsView(artistName: selection, sections: sections, sortOrder: $sortOrder,
                             showPlaylist: showPlaylist)
                .id(selection)
        } else {
            ContentUnavailableView("No Artist Selected", systemImage: "music.mic",
                                   description: Text("Select an artist to see their albums."))
        }
    }

    /// Moving an artist's songs to another artist follows them there.
    private func reloadArtists() {
        let shownTrackIDs = Set(sections.flatMap(\.tracks).map(\.id))
        artists = LibraryArtist.artists(from: tracks)
        if let selection, !artists.contains(where: { $0.id == selection }) {
            self.selection = tracks.first { shownTrackIDs.contains($0.id) }?.syncArtist
        }
        if selection == nil { selection = artists.first?.id }
        updateSections()
    }

    private func updateSections() {
        guard let selection else { return sections = [] }
        sections = ArtistAlbumSection.sections(from: tracks.filter { $0.syncArtist == selection },
                                              sortedBy: sortOrder)
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: LibraryArtist.ID?
    ArtistsView(tracks: LibraryTrack.previewTracks, selection: $selection)
        .frame(width: 800, height: 500)
        .environment(DeviceMountWatcher.preview())
        .environment(DeviceSyncModel())
}
#endif
