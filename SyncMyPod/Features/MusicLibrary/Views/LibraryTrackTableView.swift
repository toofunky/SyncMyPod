import AppKit
import SwiftData
import SwiftUI

struct LibraryTrackTableView: View {
    private static let nowPlayingColumnWidth = 16.0

    let tracks: [LibraryTrack]
    @Binding var selection: Set<LibraryTrack.ID>
    var searchText = ""
    var addTargets: [ConnectedDevice] = []
    var addToDevice: ((ConnectedDevice, [LibraryTrack]) -> Void)?
    var showPlaylist: ((LibraryPlaylist) -> Void)?

    @Environment(\.modelContext) private var context
    @Environment(MusicPlayerModel.self) private var player: MusicPlayerModel?
    @Query(sort: LibraryPlaylist.sidebarOrder) private var playlists: [LibraryPlaylist]
    @State private var sortOrder = [KeyPathComparator(\LibraryTrack.albumArtist)]
    @State private var sortedTracks: [LibraryTrack] = []
    @State private var sortKeys: [LibraryTrackSortKey] = []
    @State private var sortedBy: KeyPathComparator<LibraryTrack>?
    @State private var filteredBy = ""
    @State private var scrollTarget: LibraryTrack.ID?
    @State private var lyricsTrack: LibraryTrack?
    @State private var lyricsTrackToRemove: LibraryTrack?
    @AppStorage("libraryTableColumns") private var columnCustomization = TableColumnCustomization<LibraryTrack>()

    var body: some View {
        ScrollViewReader { proxy in
            table
                .onChange(of: scrollTarget) {
                    guard let scrollTarget else { return }
                    proxy.scrollTo(scrollTarget, anchor: .center)
                    self.scrollTarget = nil
                }
        }
    }

    private var table: some View {
        Table(sortedTracks, selection: $selection, sortOrder: $sortOrder,
              columnCustomization: $columnCustomization) {
            nowPlayingColumn
            positionColumns
            tagColumns
            audioColumns
        }
        // A fresh table lays out only visible rows; diffing a reorder or inserted search results
        // builds a row view for every changed track.
        .id(sortedBy)
        .id(filteredBy)
        .contextMenu(forSelectionType: LibraryTrack.ID.self) { ids in
            AddToDeviceMenu(devices: addTargets) { addToDevice?($0, tracks.filter { ids.contains($0.id) }) }
                .disabled(addToDevice == nil || ids.isEmpty)
            AddToPlaylistMenu(playlists: playlists) { add(ids, to: $0) }
                .disabled(ids.isEmpty)
            Divider()
            LyricsMenuItems(track: singleTrack(ids)) { lyricsTrack = $0 } remove: { lyricsTrackToRemove = $0 }
            Divider()
            ShowInPlaylistMenu(playlists: playlists(containing: ids)) { showPlaylist?($0) }
                .disabled(showPlaylist == nil || ids.isEmpty)
            Button("Show in Finder", systemImage: "folder") { showInFinder(ids) }
                .disabled(ids.isEmpty)
        } primaryAction: { ids in
            play(ids)
        }
        .modifier(LyricsEditingModifier(editing: $lyricsTrack, removing: $lyricsTrackToRemove))
        .onChange(of: tracks) {
            sortKeys = LibraryTrack.sortKeys(for: tracks)
            updateRows()
        }
        .onAppear {
            sortKeys = LibraryTrack.sortKeys(for: tracks)
            updateRows(revealingSelection: true)
        }
        .onChange(of: sortOrder) { updateRows(revealingSelection: true) }
        .onChange(of: searchText) { updateRows(revealingSelection: true) }
    }

    /// Every column must sort; file paths aren't a sort field, so clicking this one restores the default order.
    private var nowPlayingColumn: some TableColumnContent<LibraryTrack, KeyPathComparator<LibraryTrack>> {
        TableColumn("", sortUsing: KeyPathComparator(\LibraryTrack.filePath)) { track in
            NowPlayingIndicator(track: track)
        }
        .width(Self.nowPlayingColumnWidth)
        .customizationID("nowPlaying")
        .disabledCustomizationBehavior(.all)
    }

    @TableColumnBuilder<LibraryTrack, KeyPathComparator<LibraryTrack>>
    private var positionColumns: some TableColumnContent<LibraryTrack, KeyPathComparator<LibraryTrack>> {
        TableColumn("Track #", value: \.trackNumber) { track in
            Text(track.trackPosition.displayText)
                .monospacedDigit()
        }
        .customizationID("trackNumber")
        TableColumn("Disc #", value: \.discNumber) { track in
            Text(track.discPosition.displayText)
                .monospacedDigit()
        }
        .customizationID("discNumber")
    }

    @TableColumnBuilder<LibraryTrack, KeyPathComparator<LibraryTrack>>
    private var tagColumns: some TableColumnContent<LibraryTrack, KeyPathComparator<LibraryTrack>> {
        TableColumn("Title", value: \.title) { LibraryTrackTitleCell(track: $0) }
            .customizationID("title")
            .disabledCustomizationBehavior(.visibility)
        TableColumn("Artist", value: \.artist)
            .customizationID("artist")
        TableColumn("Album Artist", value: \.albumArtist)
            .customizationID("albumArtist")
        TableColumn("Album", value: \.album)
            .customizationID("album")
        TableColumn("Composer", value: \.composer)
            .customizationID("composer")
            .defaultVisibility(.hidden)
        TableColumn("Genre", value: \.genre)
            .customizationID("genre")
        TableColumn("Year", value: \.year) { track in
            Text(track.yearText)
                .monospacedDigit()
        }
        .customizationID("year")
    }

    @TableColumnBuilder<LibraryTrack, KeyPathComparator<LibraryTrack>>
    private var audioColumns: some TableColumnContent<LibraryTrack, KeyPathComparator<LibraryTrack>> {
        TableColumn("Time", value: \.duration) { track in
            Text(Duration.seconds(track.duration), format: .time(pattern: .minuteSecond))
                .monospacedDigit()
        }
        .customizationID("duration")
        TableColumn("Bitrate", value: \.bitrate) { track in
            Text("\(track.bitrate) kbps")
                .monospacedDigit()
        }
        .customizationID("bitrate")
        TableColumn("Codec", value: \.codecName)
            .customizationID("codec")
    }

    /// Also drops hidden tracks from the selection so the tag editor never edits rows the search hides.
    /// Revealing scrolls to the first selected row, since a rebuilt table starts at the top.
    private func updateRows(revealingSelection: Bool = false) {
        sortedBy = sortOrder.first
        filteredBy = searchText
        let query = TrackSearchQuery(searchText)
        let keys = sortKeys.filter { $0.matches(query) }
        if let primary = sortedBy {
            sortedTracks = LibraryTrack.sorted(tracks, keys: keys, by: primary)
        } else {
            sortedTracks = keys.map { tracks[$0.index] }
        }
        selection.formIntersection(sortedTracks.map(\.id))
        if revealingSelection {
            scrollTarget = sortedTracks.first { selection.contains($0.id) }?.id
        }
    }

    /// Adds in the order shown; `nil` makes a new playlist of them.
    private func add(_ ids: Set<LibraryTrack.ID>, to playlist: LibraryPlaylist?) {
        let selected = sortedTracks.filter { ids.contains($0.id) }
        if let playlist {
            playlist.append(selected)
        } else {
            context.insert(LibraryPlaylist(trackPaths: selected.map(\.filePath)))
        }
    }

    /// Plays the first double-clicked song, then the ones after it in the order shown.
    private func play(_ ids: Set<LibraryTrack.ID>) {
        guard let index = sortedTracks.firstIndex(where: { ids.contains($0.id) }) else { return }
        player?.play(sortedTracks, startingAt: index)
    }

    private func singleTrack(_ ids: Set<LibraryTrack.ID>) -> LibraryTrack? {
        ids.count == 1 ? sortedTracks.first(where: { ids.contains($0.id) }) : nil
    }

    private func playlists(containing ids: Set<LibraryTrack.ID>) -> [LibraryPlaylist] {
        let paths = Set(sortedTracks.filter { ids.contains($0.id) }.map(\.filePath))
        return playlists.filter { !paths.isDisjoint(with: $0.trackPaths) }
    }

    private func showInFinder(_ ids: Set<LibraryTrack.ID>) {
        let urls = sortedTracks.filter { ids.contains($0.id) }.map { URL(filePath: $0.filePath) }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }
}

#if DEBUG
#Preview {
    LibraryTrackTableView(tracks: LibraryTrack.previewTracks, selection: .constant([]),
                          addTargets: [.iPod(.preview)], addToDevice: { _, _ in })
        .modelContainer(.emptyPreview)
}
#endif
