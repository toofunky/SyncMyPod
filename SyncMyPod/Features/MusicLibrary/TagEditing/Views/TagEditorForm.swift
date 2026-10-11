import SwiftData
import SwiftUI

struct TagEditorForm: View {
    private static let textFields: [TagField] = [.title, .artist, .albumArtist, .album, .composer, .genre, .year]

    @Bindable var model: TagEditorModel
    var isLocked = false
    let onClose: () -> Void

    @Environment(\.modelContext) private var context
    @State private var tab = TagEditorTab.details

    var body: some View {
        tabs
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

    /// A sheet has no toolbar for a tab view's tabs, so the dialog switches with a segmented picker instead.
    private var tabs: some View {
        VStack(spacing: 0) {
            Picker("Tab", selection: $tab) {
                ForEach(TagEditorTab.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            .padding(.top)
            content(for: tab)
        }
    }

    @ViewBuilder
    private func content(for tab: TagEditorTab) -> some View {
        switch tab {
        case .details: details
        case .sorting: TagSortingForm(model: model)
        case .lyrics: TagLyricsForm(model: model)
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
            Button("Cancel", role: .cancel) {
                model.revert()
                onClose()
            }
            .keyboardShortcut(.cancelAction)
            .disabled(model.isSaving)
            Button("Save") { Task { await saveThenClose() } }
                .keyboardShortcut(.defaultAction)
                .disabled(model.isSaving || isLocked)
        }
        .padding()
        .background(.bar)
    }

    /// Stays open when the save fails, so the error shows over the edits.
    private func saveThenClose() async {
        if model.hasChanges { await model.save(in: context) }
        if model.errorMessage == nil { onClose() }
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
    TagEditorForm(model: TagEditorModel(tracks: LibraryTrack.previewTracks), onClose: {})
        .modelContainer(.preview)
}
#endif
