import SwiftData
import SwiftUI

/// Edits the .lrc lyric file beside a song, offering to delete it when saved empty.
struct LyricsEditorSheet: View {
    private static let minWidth = 520.0
    private static let minHeight = 440.0

    @Environment(\.dismiss) private var dismiss
    @State private var model: LyricsEditorModel
    @State private var isConfirmingDelete = false

    init(track: LibraryTrack) {
        _model = State(initialValue: LyricsEditorModel(track: track))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            TextEditor(text: $model.text)
                .font(.body.monospaced())
                .disabled(!model.isLoaded)
            Divider()
            buttons
        }
        .frame(minWidth: Self.minWidth, minHeight: Self.minHeight)
        .task { await model.load() }
        .confirmationDialog("Delete the Lyrics File?", isPresented: $isConfirmingDelete) {
            Button("Delete", role: .destructive) { Task { if await model.delete() { dismiss() } } }
        } message: {
            Text("The lyrics are empty, so saving deletes the .lrc file beside “\(model.track.title)”.")
        }
        .alert(model.isLoaded ? "Couldn't Save Lyrics" : "Couldn't Open Lyrics", isPresented: isShowingError, presenting: model.errorMessage) { _ in
            Button("OK") {}
        } message: { message in
            Text(message)
        }
    }

    private var header: some View {
        VStack(alignment: .leading) {
            Text(model.track.title)
                .font(.headline)
            Text(model.track.artist)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var buttons: some View {
        HStack {
            Spacer()
            Button("Cancel", role: .cancel) { dismiss() }
            Button("Save", action: save)
                .keyboardShortcut(.defaultAction)
                .disabled(!model.isLoaded || model.isSaving || (model.isEmpty && !model.hasFile))
        }
        .padding()
    }

    private var isShowingError: Binding<Bool> {
        Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })
    }

    private func save() {
        if model.isEmpty {
            isConfirmingDelete = true
        } else {
            Task { if await model.save() { dismiss() } }
        }
    }
}

#if DEBUG
#Preview {
    LyricsEditorSheet(track: LibraryTrack.previewTracks[0])
        .modelContainer(.emptyPreview)
}
#endif
