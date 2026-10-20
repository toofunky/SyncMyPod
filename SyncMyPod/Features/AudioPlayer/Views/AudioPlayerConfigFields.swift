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
    private static let coversInfo = "An album folder's cover.jpg, folder.jpg, cover.png or folder.png is copied "
        + "into the album's folder on the player, for players that show folder artwork instead of artwork "
        + "embedded in songs."
    private static let resizeInfo = "Artwork embedded in songs, and covers copied beside them, that's larger "
        + "than the maximum size is scaled down so its longer side fits, keeping its shape, for players that are "
        + "slow with or can't show large images. Smaller artwork is copied as it is. For Sonos, try 1000 px. "
        + "Changing this copies songs with artwork again at the next sync. Your library's files aren't changed."
    private static let lyricsInfo = "A song's .lrc lyric file, in the same folder and with the same name, is "
        + "copied beside it and renamed to match the song on the player — for example, \"01 Clocks.lrc\" beside "
        + "\"01 Clocks.m4a\" — so the player shows synced lyrics."
    private static let playlistFormatInfo = "Most players read .m3u8 playlists, which can hold any song name. "
        + "Choose .m3u for players, such as Sonos, that only read playlists written in Windows Latin-1."
    private static let latin1Note = "Songs whose album artist, album or file name uses characters outside "
        + "Windows Latin-1, such as Japanese, Chinese or Cyrillic letters, are still copied but are left out of "
        + ".m3u playlists."
    private static let podcastPlaylistsInfo = "Each podcast gets a playlist of its episodes, oldest first, so they "
        + "play in the order they came out. Useful for players without a podcast menu, or when the podcast folder "
        + "is the same as the music folder."
    private static let audiobookPlaylistsInfo = "Each audiobook gets a playlist of its files in listening order, "
        + "so its parts play one after another. Useful for players without an audiobook menu, or when the "
        + "audiobook folder is the same as the music folder."
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
            TextField("Podcast Folder", text: $config.podcastFolder, prompt: Text(Self.blankFolderPrompt))
            TextField("Audiobook Folder", text: $config.audiobookFolder, prompt: Text(Self.blankFolderPrompt))
        } footer: {
            Text("Folders inside the root folder. Songs are filed by album artist and album, podcast episodes "
                 + "by show, and audiobooks by author and book. For players that don't separate podcasts or "
                 + "audiobooks, use the music folder.")
                .foregroundStyle(.secondary)
        }
        playlistFormatSection
        Section {
            option("Preserve Track Sorting?", isOn: $config.preserveTrackSorting,
                   infoTitle: "Preserve Track Sorting", info: Self.trackSortingInfo)
            option("Preserve Album Artist?", isOn: $config.preserveAlbumArtist,
                   infoTitle: "Preserve Album Artist", info: Self.albumArtistInfo)
            option("Copy Covers?", isOn: $config.copyCovers, infoTitle: "Copy Covers", info: Self.coversInfo)
            option("Resize Covers?", isOn: $config.resizeCovers, infoTitle: "Resize Covers", info: Self.resizeInfo)
            if config.resizeCovers {
                LabeledContent("Maximum Size") {
                    HStack {
                        TextField("Maximum Size", value: $config.maxCoverSize, format: .number)
                            .labelsHidden()
                            .multilineTextAlignment(.trailing)
                        Text("px")
                    }
                }
            }
            option("Copy Lyric Files?", isOn: $config.copyLyricFiles,
                   infoTitle: "Copy Lyric Files", info: Self.lyricsInfo)
            option("Make Podcast Playlists?", isOn: $config.makesPodcastPlaylists,
                   infoTitle: "Make Podcast Playlists", info: Self.podcastPlaylistsInfo)
            option("Make Audiobook Playlists?", isOn: $config.makesAudiobookPlaylists,
                   infoTitle: "Make Audiobook Playlists", info: Self.audiobookPlaylistsInfo)
        }
    }

    private var playlistFormatSection: some View {
        Section {
            HStack {
                Picker("Playlist Format", selection: $config.playlistFormat) {
                    ForEach(PlayerPlaylistFormat.allCases) { Text($0.title).tag($0) }
                }
                InfoPopoverButton(title: "Playlist Format", message: Self.playlistFormatInfo)
            }
        } footer: {
            if config.playlistFormat == .m3u {
                Text(Self.latin1Note)
                    .foregroundStyle(.secondary)
            }
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
