import Foundation

extension HelpTopic {
    static let podcastSections = [
        HelpSection(heading: "Subscribing to a Podcast",
                    body: "Select **Podcasts** in the sidebar, click the **+** button, then paste the podcast's RSS "
                        + "feed address. The podcast's name, description and artwork are read from the feed. To "
                        + "check for new episodes, click the refresh button for one podcast or **Refresh All** at "
                        + "the top."),
        HelpSection(heading: "Choosing a Download Folder",
                    body: "Episodes are downloaded into a folder you choose in **SyncMyPod › Settings**, with a "
                        + "folder for each podcast inside it. If you haven't chosen one, SyncMyPod asks the first "
                        + "time you download an episode. The folder can't be inside your music folder, or the "
                        + "episodes would appear in your music library. Choosing another folder affects only new "
                        + "downloads."),
        HelpSection(heading: "Downloading Episodes",
                    body: "Click the download button beside an episode, or select episodes, Control-click, then "
                        + "choose **Download**. Up to three episodes download at once, and downloads carry on "
                        + "while you use the rest of the app. Each episode is tagged with its podcast's name and "
                        + "artwork when it's downloaded, and its file isn't changed after that."),
        HelpSection(heading: "Listening in SyncMyPod",
                    body: "Double-click a downloaded episode, or click the play button beside it. If you stopped "
                        + "partway through, it picks up where you left off, and the episode shows how much time is "
                        + "left. To start over, Control-click it, then choose **Play from Beginning**. While an "
                        + "episode plays, the player's skip buttons go back 15 seconds and forward 30 seconds."),
        HelpSection(heading: "Removing Episodes and Podcasts",
                    body: "To remove a downloaded episode, Control-click it, then choose **Remove Download**. To "
                        + "stop following a podcast, Control-click it, then choose **Unsubscribe…**. Removed "
                        + "episodes are moved to the Trash, and they're removed from your devices at the next sync."),
        HelpSection(heading: "Putting Podcasts on Your Devices",
                    body: "**Sync All Songs** copies every downloaded episode. With **Custom Sync**, check the "
                        + "podcasts you want in the **Podcasts** list; all of a podcast's downloaded episodes are "
                        + "copied. On an iPod, episodes appear in the Podcasts menu, grouped by podcast, oldest "
                        + "first. Only MP3 and AAC episodes can be copied to an iPod."),
        HelpSection(heading: "Audio Players",
                    body: "Episodes are copied into the player's **Podcast Folder**, set in its **Settings** tab, "
                        + "with a folder for each podcast. For players that don't keep podcasts separate, set it "
                        + "to the same folder as your music. With **Make Podcast Playlists** on, each podcast also "
                        + "gets a playlist of its episodes, oldest first, so they play in the order they came out."),
        HelpSection(heading: "Picking Up Where You Left Off",
                    body: "iPods and most players remember your place in each episode. SyncMyPod never replaces an "
                        + "episode that's already on a device, so your place is kept when you sync again. When you "
                        + "connect an iPod, SyncMyPod picks up where you got to on it, if that's further along than "
                        + "where you stopped in SyncMyPod. On an iPod nano (7th generation), that happens after "
                        + "you sync. On an iPod, new episodes show a dot until you play them."),
        HelpSection(heading: "Podcasts in the Music Menus",
                    body: "On an iPod (video) 5G or 5.5G, episodes also appear under Songs, Artists and Albums. "
                        + "That's how those iPods list podcasts, even when synced with iTunes. iPod classic and "
                        + "iPod nano models list them only under Podcasts."),
    ]
}
