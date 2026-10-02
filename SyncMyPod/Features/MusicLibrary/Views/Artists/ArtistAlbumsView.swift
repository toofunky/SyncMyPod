import SwiftUI

/// Every album by one artist, each followed by its songs.
struct ArtistAlbumsView: View {
    let artistName: String
    let sections: [ArtistAlbumSection]
    @Binding var sortOrder: AlbumSortOrder

    var body: some View {
        VStack(spacing: 0) {
            header
            albumList
        }
    }

    private var header: some View {
        HStack {
            Text(artistName)
                .font(.title.bold())
                .lineLimit(1)
            Spacer()
            Picker("Sort By", selection: $sortOrder) {
                ForEach(ArtistAlbumSection.sortOrders) { Text($0.title).tag($0) }
            }
            .pickerStyle(.menu)
            .fixedSize()
            .controlSize(.small)
        }
        .padding()
    }

    private var albumList: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(sections) { section in
                    ArtistAlbumRow(section: section)
                        .padding(.vertical)
                    if section.id != sections.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

#if DEBUG
#Preview {
    ArtistAlbumsView(artistName: "OutKast", sections: ArtistAlbumSection.sections(from: LibraryTrack.previewTracks),
                     sortOrder: .constant(.year))
        .frame(width: 500, height: 600)
}
#endif
