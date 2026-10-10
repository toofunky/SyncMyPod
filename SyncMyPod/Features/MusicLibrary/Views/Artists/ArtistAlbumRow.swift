import SwiftData
import SwiftUI

/// One album in the Artists view: the cover on the left, with the album's details and songs beside it.
struct ArtistAlbumRow: View {
    private static let artworkSize = 200.0
    private static let columnSpacing = 20.0

    let section: ArtistAlbumSection
    var onPlay: ((LibraryTrack) -> Void)?
    var playlists: [LibraryPlaylist] = []
    var editLyrics: (LibraryTrack) -> Void = { _ in }
    var removeLyrics: (LibraryTrack) -> Void = { _ in }
    var showPlaylist: ((LibraryPlaylist) -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: Self.columnSpacing) {
            AlbumArtworkView(path: section.album.artworkPath, fingerprint: section.album.artworkFingerprint)
                .frame(width: Self.artworkSize)
            VStack(alignment: .leading) {
                details
                Divider()
                tracks
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading) {
            Text(section.album.title)
                .font(.title2)
                .fontWeight(.semibold)
            Text(section.album.summary(duration: section.duration))
                .foregroundStyle(.secondary)
        }
    }

    private var tracks: some View {
        ForEach(section.tracks) { track in
            if section.hasSeveralDiscs, track.id == firstTrackID(onDiscOf: track) {
                Text(track.discNumber > 0 ? "Disc \(track.discNumber)" : "Other")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            AlbumTrackRow(track: track, albumArtist: section.album.artist)
                .contentShape(.rect)
                .onTapGesture(count: 2) { onPlay?(track) }
                .contextMenu {
                    LibrarySongContextMenu(tracks: [track], playlists: playlists, editLyrics: editLyrics,
                                           removeLyrics: removeLyrics, showPlaylist: showPlaylist)
                }
        }
    }

    private func firstTrackID(onDiscOf track: LibraryTrack) -> LibraryTrack.ID? {
        section.tracks.first { $0.discNumber == track.discNumber }?.id
    }
}

#if DEBUG
#Preview {
    if let section = ArtistAlbumSection.sections(from: LibraryTrack.previewTracks).first {
        ArtistAlbumRow(section: section)
            .frame(width: 600)
            .padding()
            .modelContainer(.emptyPreview)
    }
}
#endif
