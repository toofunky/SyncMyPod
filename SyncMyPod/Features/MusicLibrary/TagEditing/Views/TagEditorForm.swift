import SwiftData
import SwiftUI

struct TagEditorForm: View {
    private static let textFields: [TagField] = [.title, .artist, .albumArtist, .album, .composer, .genre, .year]

    @Bindable var model: TagEditorModel
    var isLocked = false

    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            Tab("Details", systemImage: "info.circle") { details }
            Tab("Sorting", systemImage: "arrow.up.arrow.down") { TagSortingForm(model: model) }
            Tab("Lyrics", systemImage: "quote.bubble") { TagLyricsForm(model: model) }
        }
        .disabled(model.isSaving)
        .safeAreaInset(edge: .bottom) { actions }
        .task {
            await model.loadArtwork()
            await model.loadLyrics()
        }
        .alert("Couldn't Save Tags", isPresented: isShowingError) {
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var details: some View {
        Form {
            Section {
                TagArtworkWell(artwork: model.displayedArtwork,
                               onReplace: { model.replaceArtwork(with: $0) },
                               onRemove: model.removeArtwork)
            } footer: {
                Text(summary)
            }
            Section {
                ForEach(Self.textFields, id: \.self) { field in
                    TextField(field.label, text: binding(for: field), prompt: Text(model.placeholder(for: field)))
                }
            }
            Section {
                numberPair("Track", number: .trackNumber, count: .trackCount)
                numberPair("Disc", number: .discNumber, count: .discCount)
            }
        }
        .formStyle(.grouped)
    }

    private var summary: String {
        guard model.tracks.count > 1 else { return model.tracks.first.map { URL(filePath: $0.filePath).lastPathComponent } ?? "" }
        return "\(model.tracks.count) songs"
    }

    private var actions: some View {
        HStack {
            if model.isSaving {
                ProgressView()
                    .controlSize(.small)
            } else if isLocked {
                Text("Saving resumes after the scan or sync.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Revert", action: model.revert)
                .disabled(!model.hasChanges || model.isSaving)
            Button("Save") { Task { await model.save(in: context) } }
                .keyboardShortcut("s")
                .disabled(!model.hasChanges || model.isSaving || isLocked)
        }
        .padding()
        .background(.bar)
    }

    private var isShowingError: Binding<Bool> {
        Binding { model.errorMessage != nil } set: { if !$0 { model.errorMessage = nil } }
    }

    private func binding(for field: TagField) -> Binding<String> {
        Binding { model.values[field, default: ""] } set: { model.values[field] = $0 }
    }

    private func numberPair(_ title: String, number: TagField, count: TagField) -> some View {
        TagNumberPairField(title: title, number: binding(for: number), count: binding(for: count),
                           numberPrompt: model.placeholder(for: number),
                           countPrompt: model.placeholder(for: count))
    }
}

#if DEBUG
#Preview {
    TagEditorForm(model: TagEditorModel(tracks: LibraryTrack.previewTracks))
        .modelContainer(.preview)
}
#endif
