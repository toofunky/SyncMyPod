import Foundation

extension HelpTopic {
    static let audiobookSections = [
        HelpSection(heading: "Choosing Your Audiobook Folder",
                    body: "Select **Audiobooks** in the sidebar, click **Choose Folder…**, then pick the folder that "
                        + "holds your audiobooks. You can also choose it in **SyncMyPod › Settings**. The folder "
                        + "can't be inside or around your music or podcast folder, or their files would be mixed "
                        + "together. SyncMyPod scans it the first time you open Audiobooks; click **Rescan** after "
                        + "adding books."),
        HelpSection(heading: "How Books Are Found",
                    body: "Each folder of audio files is one book, such as **Author › Book › 01.mp3**. Folders "
                        + "named like **CD 1** or **Disc 2** inside a book are part of it. A .m4b file on its own "
                        + "is a book by itself, and .m4b parts that share an album tag stay together. A book is "
                        + "named from its files' album and artist tags, or from its folders when they're untagged. "
                        + "Its files play by disc and track number, then by file name."),
        HelpSection(heading: "Listening in SyncMyPod",
                    body: "Double-click a book to carry on where you left off, or click **Play** beside its title. "
                        + "Double-click a file to start from there. The files play one after another, and the book "
                        + "shows how much time is left. A bookmark marks the file where you stopped. To start "
                        + "over, Control-click the book, then choose **Play from Beginning**. The player's skip "
                        + "buttons go back 15 seconds and forward 30 seconds. Your place in SyncMyPod is kept "
                        + "separately from your place on your devices."),
        HelpSection(heading: "Putting Audiobooks on Your Devices",
                    body: "**Sync All Songs** copies every book. With **Custom Sync**, check the books you want in "
                        + "the **Audiobooks** list; all of a book's files are copied. Books removed from your "
                        + "audiobook folder are removed from your devices at the next sync. Only MP3 and AAC files, "
                        + "including .m4b, can be copied to an iPod."),
        HelpSection(heading: "Audiobooks on an iPod",
                    body: "Books appear in the iPod's Audiobooks menu, which lists every book's files together. "
                        + "With **Make Audiobook Playlists** on in the iPod's **Settings** tab, each book also gets "
                        + "a playlist of its files in order, under Playlists, so you can play one book at a time. "
                        + "The iPod remembers your place in each file and leaves books out when shuffling."),
        HelpSection(heading: "Audio Players",
                    body: "Books are copied into the player's **Audiobook Folder**, set in its **Settings** tab, "
                        + "in a folder for each author and book. For players that don't keep audiobooks separate, "
                        + "set it to the same folder as your music. With **Make Audiobook Playlists** on, each book "
                        + "also gets a playlist of its files in listening order."),
        HelpSection(heading: "Picking Up Where You Left Off",
                    body: "iPods and most players remember your place in a book. SyncMyPod never replaces a file "
                        + "that's already on a device, so your place is kept when you sync again."),
    ]
}
