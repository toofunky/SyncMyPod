import SwiftData
import SwiftUI

struct TagSortingForm: View {
    private static let fields: [TagField] = [.sortTitle, .sortArtist, .sortAlbumArtist, .sortAlbum, .sortComposer]

    @Bindable var model: TagEditorModel

    var body: some View {
        Form {
            Section {
                ForEach(Self.fields, id: \.self) { field in
                    HStack {
                        TextField(field.label, text: binding(for: field), prompt: Text(model.placeholder(for: field)))
                        clearButton(for: field)
                    }
                }
            } footer: {
                Text("Songs sort on the iPod by these names. Empty fields sort without a leading “A”, “An” or “The”.")
            }
        }
        .formStyle(.grouped)
    }

    private func clearButton(for field: TagField) -> some View {
        Button("Clear \(field.label)", systemImage: "xmark.circle.fill") {
            model.values[field] = ""
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .help("Clear \(field.label)")
        .opacity(model.values[field, default: ""].isEmpty ? 0 : 1)
        .disabled(model.values[field, default: ""].isEmpty)
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
