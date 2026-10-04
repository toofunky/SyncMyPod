import Foundation

extension HelpTopic {
    var summary: String {
        switch self {
        case .gettingStarted: "Get your music from a folder on your Mac onto a click-wheel iPod in four steps."
        case .musicLibrary: "SyncMyPod reads your music straight from a folder of audio files."
        case .tagEditor: "Fix song details and cover art without leaving the app."
        case .playlists: "Build playlists in SyncMyPod and take them with you on your iPod."
        case .syncing: "Choose what goes on your iPod and keep it up to date."
        case .troubleshooting: "Solutions to common problems."
        }
    }

    var sections: [HelpSection] {
        switch self {
        case .gettingStarted: Self.gettingStartedSections
        case .musicLibrary: Self.musicLibrarySections
        case .tagEditor: Self.tagEditorSections
        case .playlists: Self.playlistSections
        case .syncing: Self.syncingSections
        case .troubleshooting: Self.troubleshootingSections
        }
    }

    private static let gettingStartedSections = [
        HelpSection(heading: "Before You Begin",
                    body: "You need an iPod (video) 5G or 5.5G, or an iPod classic 6G, 6.5G or 7G. Turn on disk mode "
                        + "so the iPod mounts as a volume in Finder. You don't need iTunes, Music or Finder to sync."),
        HelpSection(heading: "1. Choose Your Music Folder",
                    body: "Select **Songs** in the sidebar, click **Choose Folder…**, then pick "
                        + "the folder that contains your music. SyncMyPod scans it and lists every song it finds. "
                        + "Select **Albums** to browse your library by cover art."),
        HelpSection(heading: "2. Connect Your iPod",
                    body: "Plug in your iPod with a USB cable. Select **iPod** in the sidebar to see its songs, "
                        + "sync options and device details."),
        HelpSection(heading: "3. Choose What to Sync",
                    body: "In the **Sync** tab, choose **Sync All Songs** to copy your whole library, or "
                        + "**Custom Sync** to pick albums, genres and playlists."),
        HelpSection(heading: "4. Sync",
                    body: "Click **Sync Now**. Wait for the sync to finish before you eject the iPod."),
    ]

    private static let musicLibrarySections = [
        HelpSection(heading: "Supported Files",
                    body: "SyncMyPod reads AAC and Apple Lossless (`.m4a`), MP3, FLAC, AIFF and WAV files. "
                        + "FLAC, AIFF and WAV songs sync only to other audio players, not to iPods. Your songs stay "
                        + "where they are on disk. SyncMyPod never moves or renames them."),
        HelpSection(heading: "Choosing and Rescanning",
                    body: "Click **Choose Folder…** in the toolbar to switch to a different folder. When you add, "
                        + "remove or change files in Finder, click **Rescan** to update the library."),
        HelpSection(heading: "Browsing",
                    body: "Click a column heading to sort the list by that column. Click it again to reverse "
                        + "the order."),
        HelpSection(heading: "Adding Songs Quickly",
                    body: "To copy a few songs without changing your sync settings, select them, Control-click, "
                        + "then choose **Add to iPod**. Your iPod must be connected."),
        HelpSection(heading: "Light and Dark Mode",
                    body: "Use the toolbar button to switch between light and dark mode."),
    ]

    private static let tagEditorSections = [
        HelpSection(heading: "Opening the Tag Editor",
                    body: "Select one or more songs in Songs, then click **Tag Editor** in the toolbar. "
                        + "The editor opens on the right side of the window."),
        HelpSection(heading: "Editing Several Songs",
                    body: "When the selected songs have different values for a field, the field shows **Mixed**. "
                        + "Anything you type replaces the value for every selected song."),
        HelpSection(heading: "Cover Art",
                    body: "Drag a JPEG or PNG image onto the artwork well, or click **Choose…** to pick one. "
                        + "Click **Remove** to delete the artwork."),
        HelpSection(heading: "Sort Order",
                    body: "The **Sorting** tab sets the names a song sorts by, such as sorting David Bowie as "
                        + "\"Bowie, David\". When a field is empty, the song sorts by its name without a leading "
                        + "\"A\", \"An\" or \"The\", as iTunes does."),
        HelpSection(heading: "Saving Changes",
                    body: "Click **Save** to write your changes to the music files, or **Revert** to discard them. "
                        + "If a scan or sync is running, saving resumes once it finishes. On the next sync, "
                        + "the changed songs are updated on your iPod."),
    ]

    private static let playlistSections = [
        HelpSection(heading: "Creating a Playlist",
                    body: "Select **Playlists** in the sidebar, then click the **+** button at the top right. Type a name at the top "
                        + "of the playlist."),
        HelpSection(heading: "Adding Songs",
                    body: "In Songs, select songs, Control-click, then choose **Add to Playlist**. Pick "
                        + "a playlist, or choose **New Playlist** to create one from the selection."),
        HelpSection(heading: "Arranging and Removing Songs",
                    body: "Drag songs to change their order. To take songs out, select them, Control-click, then "
                        + "choose **Remove from Playlist**. The songs stay in your library."),
        HelpSection(heading: "Deleting a Playlist",
                    body: "Control-click the playlist in the sidebar, then choose **Delete Playlist**."),
        HelpSection(heading: "Putting Playlists on Your iPod",
                    body: "**Sync All Songs** includes every playlist. With **Custom Sync**, choose the playlists "
                        + "you want in the **Playlists** list."),
    ]

    private static let syncingSections = [
        HelpSection(heading: "The iPod Tabs",
                    body: "**Library** shows the songs and playlists already on the iPod. **Sync** is where you "
                        + "choose what to copy. **Settings** holds options for how songs are copied. **Device** "
                        + "shows the model, capacity and other details."),
        HelpSection(heading: "Sync All Songs or Custom Sync",
                    body: "**Sync All Songs** copies every song and playlist in your music library. **Custom Sync** "
                        + "lets you check artists and albums, genres, and playlists. SyncMyPod remembers your "
                        + "choices for each iPod."),
        HelpSection(heading: "Before You Sync",
                    body: "The bar at the bottom shows how many songs will be added, updated and removed, and how "
                        + "much free space the iPod has. **Sync Now** is unavailable if the songs won't fit."),
        HelpSection(heading: "Removing Songs",
                    body: "Songs that are no longer selected, whose files were deleted, or that duplicate another "
                        + "song are removed from the iPod. SyncMyPod asks before it removes anything. Your music "
                        + "library isn't affected."),
        HelpSection(heading: "Preserve Album Artist",
                    body: "When a song's artist differs from its album artist, this option in **Settings** files "
                        + "the song under the album artist and adds the guest artist to the title. This keeps "
                        + "albums together when you browse by artist. Your music files aren't changed."),
        HelpSection(heading: "Lyrics",
                    body: "Lyrics embedded in a song are shown on the iPod. Turn on **Sync Lyrics Sidecar** in "
                        + "**Settings** to also add the lyrics from a song's .lrc file when the song has none of "
                        + "its own. The iPod shows them as plain text, without timings. Your music files aren't "
                        + "changed. Lyrics aren't shown on the iPod nano (6th and 7th generation)."),
        HelpSection(heading: "Play Counts",
                    body: "Songs you play on the iPod are counted, and SyncMyPod merges those play counts during "
                        + "the next sync."),
    ]

    private static let troubleshootingSections = [
        HelpSection(heading: "My iPod Doesn't Appear",
                    body: "Make sure disk mode is on and the iPod appears in Finder. Only click-wheel iPods with "
                        + "video (5G and later) and iPod classic models are supported."),
        HelpSection(heading: "My Changes Disappear After Syncing",
                    body: "If Finder or Music also manages your iPod, it can replace SyncMyPod's changes a few "
                        + "seconds after a sync. SyncMyPod warns you when this happens. In Music › Settings › "
                        + "Devices, turn on “Prevent iPods, iPhones, and iPads from syncing automatically”, then "
                        + "sync again."),
        HelpSection(heading: "Not Enough Space",
                    body: "Use **Custom Sync** to choose fewer albums, genres or playlists until the selection fits."),
        HelpSection(heading: "Songs Are Missing From the Library",
                    body: "Check that the files are AAC, Apple Lossless or MP3 and are inside your music folder, "
                        + "then click **Rescan**."),
    ]
}
