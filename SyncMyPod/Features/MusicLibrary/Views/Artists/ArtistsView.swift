import SwiftUI

struct ArtistsView: View {
    private static let listMinWidth = 160.0
    private static let listIdealWidth = 220.0
    private static let listMaxWidth = 320.0
    private static let detailMinWidth = 300.0

    let tracks: [LibraryTrack]
    var searchText = ""
    @Binding var selection: LibraryArtist.ID?
    var showPlaylist: ((LibraryPlaylist) -> Void)?

    @AppStorage("artistAlbumSortOrder") private var sortOrder = AlbumSortOrder.year
    @State private var artists: [LibraryArtist] = []
    @State private var sections: [ArtistAlbumSection] = []

    var body: some View {
        HSplitView {
            ArtistListView(artists: visibleArtists, selection: $selection)
                .frame(minWidth: Self.listMinWidth, idealWidth: Self.listIdealWidth, maxWidth: Self.listMaxWidth)
            detail
                .frame(minWidth: Self.detailMinWidth, maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: tracks, initial: true) {
            artists = LibraryArtist.artists(from: tracks)
            if selection == nil { selection = artists.first?.id }
            updateSections()
        }
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
