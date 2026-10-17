import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(DeviceSyncModel.self) private var syncModel
    @Environment(MusicPlayerModel.self) private var player: MusicPlayerModel?
    @State private var selection: SidebarItem? = .library(.artists)
    @State private var selectedPlaylistID: UUID?
    @State private var selectedPodcastID: UUID?
    @State private var playlistTrackSelections: [UUID: Set<PlaylistEntry.ID>] = [:]
    @State private var libraryModel = MusicLibraryModel()
    @State private var librarySelection = Set<LibraryTrack.ID>()
    @State private var selectedAlbumID: LibraryAlbum.ID?
    @State private var selectedArtistID: LibraryArtist.ID?
    @State private var isShowingAlbum = false
    @Query(filter: LibraryPlaylist.favoritesFilter) private var favorites: [LibraryPlaylist]

    var body: some View {
        NavigationSplitView {
            AppSidebar(selection: $selection)
        } detail: {
            switch selection {
            case .device(let id): DeviceDetailView(deviceID: id)
            case .noDevice: DeviceDetailView(deviceID: nil)
            case .playlists: PlaylistsView(selection: $selectedPlaylistID, trackSelections: $playlistTrackSelections)
            case .podcasts: PodcastsView(selection: $selectedPodcastID)
            case .library(let section):
                libraryView(section)
            case nil:
                libraryView(.artists)
            }
        }
        .inspector(isPresented: inspectorPresented) {
            AlbumTracksInspector(albumID: selectedAlbumID, isShowing: $isShowingAlbum, showPlaylist: show)
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
        .environment(\.favoriteTrackPaths, Set(favorites.first?.trackPaths ?? []))
        .environment(\.isTagEditingLocked, libraryModel.isScanning || syncModel.isSyncing)
    }

    private func libraryView(_ section: LibrarySection) -> some View {
        MusicLibraryView(model: libraryModel, section: section, selection: $librarySelection,
                         albumSelection: $selectedAlbumID, artistSelection: $selectedArtistID, showPlaylist: show)
    }

    private var showsPlayer: Bool { player != nil && selection?.isDevice != true }

    private var librarySection: LibrarySection? {
        if case .library(let section) = selection { section } else { nil }
    }

    /// Only Albums has an inspector, showing the selected album's songs.
    private var inspectorPresented: Binding<Bool> {
        Binding(get: {
            librarySection == .albums && isShowingAlbum && selectedAlbumID != nil
        }, set: { isPresented in
            if librarySection == .albums { isShowingAlbum = isPresented }
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
        .environment(DeviceMountWatcher.preview(connectedDevices: [.iPod(.preview)]))
        .environment(DeviceSyncModel())
        .environment(MusicPlayerModel())
        .environment(PodcastsModel())
        .environment(\.iTunesDBLoader, .preview)
        .modelContainer(.preview)
}
#endif
