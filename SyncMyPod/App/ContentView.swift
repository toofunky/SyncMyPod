import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(IPodSyncModel.self) private var syncModel
    @Environment(MusicPlayerModel.self) private var player: MusicPlayerModel?
    @State private var selection: SidebarItem? = .library(.artists)
    @State private var selectedPlaylistID: UUID?
    @State private var playlistTrackSelections: [UUID: Set<PlaylistEntry.ID>] = [:]
    @State private var libraryModel = MusicLibraryModel()
    @State private var librarySelection = Set<LibraryTrack.ID>()
    @State private var selectedAlbumID: LibraryAlbum.ID?
    @State private var selectedArtistID: LibraryArtist.ID?
    @State private var isShowingTagEditor = false
    @State private var isShowingAlbum = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            switch selection {
            case .device: DeviceDetectionView()
            case .playlists: PlaylistsView(selection: $selectedPlaylistID, trackSelections: $playlistTrackSelections)
            case .library(let section):
                libraryView(section)
            case nil:
                libraryView(.artists)
            }
        }
        .inspector(isPresented: inspectorPresented) {
            LibraryInspector(section: librarySection, trackSelection: librarySelection,
                             albumID: selectedAlbumID, isLocked: libraryModel.isScanning || syncModel.isSyncing,
                             isShowingTagEditor: $isShowingTagEditor, isShowingAlbum: $isShowingAlbum)
        }
        .contentMargins(.bottom, showsPlayer ? MusicPlayerOverlay.clearance : 0, for: .scrollContent)
        .overlay(alignment: .bottom) {
            if let player, showsPlayer {
                MusicPlayerOverlay(player: player)
                    .padding()
            }
        }
        .onChange(of: selectedAlbumID) { isShowingAlbum = selectedAlbumID != nil }
        .frame(minWidth: 420, minHeight: 320)
    }

    private var sidebar: some View {
        List(selection: $selection) {
            ForEach(SidebarItem.allItems) { item in
                if item == .device {
                    DeviceSidebarRow()
                } else {
                    Label(item.title, systemImage: item.systemImage)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            BuyMeACoffeeButton()
                .padding()
        }
    }

    private func libraryView(_ section: LibrarySection) -> some View {
        MusicLibraryView(model: libraryModel, section: section, selection: $librarySelection,
                         albumSelection: $selectedAlbumID, artistSelection: $selectedArtistID, showPlaylist: show)
    }

    private var showsPlayer: Bool { player != nil && selection != .device }

    private var librarySection: LibrarySection? {
        if case .library(let section) = selection { section } else { nil }
    }

    /// Songs show the tag editor and Albums show the selected album, so each keeps its own toggle.
    private var inspectorPresented: Binding<Bool> {
        Binding(get: {
            switch librarySection {
            case .songs: isShowingTagEditor
            case .albums: isShowingAlbum && selectedAlbumID != nil
            default: false
            }
        }, set: { isPresented in
            switch librarySection {
            case .songs: isShowingTagEditor = isPresented
            case .albums: isShowingAlbum = isPresented
            default: break
            }
        })
    }

    private func show(_ playlist: LibraryPlaylist) {
        selectedPlaylistID = playlist.playlistID
        selection = .playlists
    }
}

#if DEBUG
#Preview {
    ContentView()
        .environment(IPodMountWatcher.preview(connectedDevice: .preview))
        .environment(IPodSyncModel())
        .environment(MusicPlayerModel())
        .environment(\.iTunesDBLoader, .preview)
        .modelContainer(.preview)
}
#endif
