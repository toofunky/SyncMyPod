import SwiftUI

/// The editable parts of a player's setup, shared by adding a player and its settings.
struct AudioPlayerConfigFields: View {
    private static let trackSortingInfo = "Copies are named with their track number, and their disc number when "
        + "an album has more than one disc — for example, \"01 Clocks.m4a\" or \"2-05 Clocks.m4a\" — for players "
        + "that sort songs by file name. Otherwise copies keep the name they have in your library."
    private static let albumArtistInfo = "When a song's artist differs from its album artist, the copy on the "
        + "player is tagged with the album artist as its artist and the guest artist is added to the title — for "
        + "example, \"Song — Guest Artist\". This keeps albums together when you browse by artist. Your music "
        + "files aren't changed."
    private static let blankFolderPrompt = "Leave blank to use the root folder"

    @Binding var config: AudioPlayerConfig
    let rootDescription: String

    var body: some View {
        Section {
            TextField("Name", text: $config.name)
            LabeledContent("Root Folder", value: rootDescription)
        }
        Section {
            TextField("Music Folder", text: $config.musicFolder, prompt: Text(Self.blankFolderPrompt))
            TextField("Playlist Folder", text: $config.playlistFolder, prompt: Text(Self.blankFolderPrompt))
        } footer: {
            Text("Folders inside the root folder. Songs are filed by album artist and album.")
                .foregroundStyle(.secondary)
        }
        Section {
            option("Preserve Track Sorting?", isOn: $config.preserveTrackSorting,
                   infoTitle: "Preserve Track Sorting", info: Self.trackSortingInfo)
            option("Preserve Album Artist?", isOn: $config.preserveAlbumArtist,
                   infoTitle: "Preserve Album Artist", info: Self.albumArtistInfo)
        }
    }

    private func option(_ title: String, isOn: Binding<Bool>, infoTitle: String, info: String) -> some View {
        HStack {
            Toggle(title, isOn: isOn)
            InfoPopoverButton(title: infoTitle, message: info)
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var config = AudioPlayerDevice.preview.config
    Form {
        AudioPlayerConfigFields(config: $config, rootDescription: "FIIO")
    }
    .formStyle(.grouped)
}
#endif
