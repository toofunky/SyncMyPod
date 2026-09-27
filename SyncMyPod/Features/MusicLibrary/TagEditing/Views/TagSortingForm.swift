import SwiftData
import SwiftUI

struct TagSortingForm: View {
    private static let fields: [TagField] = [.sortTitle, .sortArtist, .sortAlbumArtist, .sortAlbum, .sortComposer]

    @Bindable var model: TagEditorModel

    var body: some View {
        Form {
            Section {
                ForEach(Self.fields, id: \.self) { field in
                    TextField(field.label, text: binding(for: field), prompt: Text(model.placeholder(for: field)))
                }
            } footer: {
                Text("Songs sort on the iPod by these names. Empty fields sort without a leading “A”, “An” or “The”.")
            }
        }
        .formStyle(.grouped)
    }

    private func binding(for field: TagField) -> Binding<String> {
        Binding { model.values[field, default: ""] } set: { model.values[field] = $0 }
    }
}

#if DEBUG
#Preview {
    TagSortingForm(model: TagEditorModel(tracks: LibraryTrack.previewTracks))
        .modelContainer(.preview)
}
#endif
