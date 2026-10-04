import SwiftData
import SwiftUI

struct TagLyricsForm: View {
    @Bindable var model: TagEditorModel

    var body: some View {
        if model.canEditLyrics {
            VStack(alignment: .leading) {
                TextEditor(text: $model.lyrics)
                    .disabled(model.originalLyrics == nil)
                    .accessibilityLabel("Lyrics")
                Text("Shown on the iPod. A song's .lrc lyric file isn't changed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        } else {
            ContentUnavailableView("Multiple Songs Selected", systemImage: "quote.bubble",
                                   description: Text("Lyrics can be edited one song at a time."))
        }
    }
}

#if DEBUG
#Preview("One Song") {
    TagLyricsForm(model: TagEditorModel(tracks: Array(LibraryTrack.previewTracks.prefix(1))))
        .modelContainer(.preview)
}

#Preview("Several Songs") {
    TagLyricsForm(model: TagEditorModel(tracks: LibraryTrack.previewTracks))
        .modelContainer(.preview)
}
#endif
