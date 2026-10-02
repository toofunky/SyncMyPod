import SwiftUI

struct AlbumGridView: View {
    private static let gridSpacing = 16.0

    let tracks: [LibraryTrack]
    var searchText = ""
    @Binding var selection: LibraryAlbum.ID?

    @AppStorage("albumGridColumns") private var columnCount = 4.0
    @AppStorage("albumSortOrder") private var sortOrder = AlbumSortOrder.albumArtist
    @State private var albums: [LibraryAlbum] = []
    @State private var visibleAlbums: [LibraryAlbum] = []
    @State private var scrollTarget: LibraryAlbum.ID?

    var body: some View {
        VStack(spacing: 0) {
            AlbumGridControls(sortOrder: $sortOrder, columnCount: $columnCount)
            grid
        }
        .overlay {
            if visibleAlbums.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .onChange(of: tracks) {
            albums = LibraryAlbum.albums(from: tracks)
            updateVisibleAlbums()
        }
        .onAppear {
            albums = LibraryAlbum.albums(from: tracks)
            updateVisibleAlbums(revealingSelection: true)
        }
        .onChange(of: sortOrder) { updateVisibleAlbums(revealingSelection: true) }
        .onChange(of: searchText) { updateVisibleAlbums(revealingSelection: true) }
    }

    private var grid: some View {
        ScrollViewReader { proxy in
            scrollView
                .onChange(of: scrollTarget) {
                    guard let scrollTarget else { return }
                    proxy.scrollTo(scrollTarget, anchor: .center)
                    self.scrollTarget = nil
                }
        }
    }

    private var scrollView: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: Self.gridSpacing) {
                ForEach(visibleAlbums) { album in
                    Button { toggle(album) } label: {
                        AlbumGridCell(album: album, isSelected: album.id == selection)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private var gridColumns: [GridItem] {
        let range = AlbumGridControls.columnRange
        let count = Int(min(max(columnCount, range.lowerBound), range.upperBound))
        return Array(repeating: GridItem(.flexible(), spacing: Self.gridSpacing, alignment: .top), count: count)
    }

    private func toggle(_ album: LibraryAlbum) {
        selection = selection == album.id ? nil : album.id
    }

    private func updateVisibleAlbums(revealingSelection: Bool = false) {
        let query = TrackSearchQuery(searchText)
        visibleAlbums = sortOrder.sorted(albums.filter { $0.matches(query) })
        if revealingSelection, let selection, visibleAlbums.contains(where: { $0.id == selection }) {
            scrollTarget = selection
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: LibraryAlbum.ID?
    AlbumGridView(tracks: LibraryTrack.previewTracks, selection: $selection)
        .frame(width: 700, height: 500)
}
#endif
