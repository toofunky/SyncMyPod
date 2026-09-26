# SyncMyPod

SyncMyPod is a native macOS app for syncing music from a folder on your Mac to a classic, click-wheel iPod. You don't need iTunes, Music or Finder. It reads and writes the iPod's own `iTunesDB` and `ArtworkDB` directly, so your library stays in plain audio files on disk and your iPod stays in sync with them.

## Supported iPods

| Model | Generation | Database signing |
| --- | --- | --- |
| iPod (video) | 5G, 5.5G | Not required |
| iPod classic | 6G, 6.5G, 7G | hash58 |

## Features

- **Music Library**: scan any folder of AAC and ALAC (`.m4a`) and MP3 files. The library shows track, disc, album artist and codec, and sorts by album, disc and track.
- **Tag editor**: edit tags and cover art from an inspector. Changes are written back to the MP4 or ID3 tags in the source files.
- **Playlists**: create playlists in the app and sync them to the iPod.
- **Flexible syncing**: sync the entire library, or pick the artists, albums, genres and playlists you want. The app remembers your choices for each iPod.
- **Album artwork**: embedded cover art is resized for the iPod and deduplicated in the `ArtworkDB`.
- **Change detection**: when a file's tags or artwork change, the track is updated on the iPod in place instead of being added again.
- **Housekeeping**: songs you deselect are removed from the iPod, play counts recorded on the iPod are merged back, and unused artwork is compacted.
- **Preserve Album Artist**: an option you set for each iPod. When a song's artist differs from its album artist, the song is filed under the album artist and the guest artist is added to the title (for example, "Die With A Smile — Bruno Mars"). This keeps albums together when you browse by artist.
- **Sync verification**: the app warns you if Finder or Music rewrites the iPod's database after a sync.
- **Automatic updates** through [Sparkle](https://sparkle-project.org).
- Light and dark mode.

See [FEATURES.md](FEATURES.md) for the roadmap.

## Requirements

- macOS 27.0 or later
- A supported iPod with disk mode enabled, so it mounts as a volume in Finder

## Installation

Download the latest `SyncMyPod-<version>.zip` from [Releases](https://github.com/toofunky/SyncMyPod/releases/latest), unzip it and move `SyncMyPod.app` to `/Applications`. After that, Sparkle installs updates for you.

## Usage

1. Open **Music Library** and choose the folder that contains your music. The app scans the folder and indexes it.
2. Connect your iPod. It appears under **iPod** in the sidebar with its model and capacity.
3. Choose **Sync All Songs**, or choose **Custom Sync** and select artists, albums, genres or playlists.
4. Click **Sync** and wait for it to finish before ejecting the iPod.

> [!TIP]
> If the Finder or Music sidebar also manages your iPod, macOS may overwrite SyncMyPod's changes a few seconds after a sync. SyncMyPod warns you when this happens. To prevent it, don't let Finder sync the device.

## Building from Source

Requirements: Xcode 26 or later. Swift Package Manager fetches the only dependency, Sparkle.

```sh
git clone https://github.com/toofunky/SyncMyPod.git
cd SyncMyPod
xcodebuild -scheme SyncMyPod -destination 'platform=macOS' build
```

### Tests

```sh
xcodebuild -scheme SyncMyPod -destination 'platform=macOS' test
```

Some tests run against real databases copied from a device. To enable them, copy `iTunesDB`, `ArtworkDB` and `PlayCounts` from an iPod's `iPod_Control` folder into `SyncMyPodTests/Fixtures/`. Git ignores those files, and without them the tests are skipped.

### Project Layout

```
SyncMyPod/
  App/               App entry point, sidebar and appearance
  Features/
    DeviceDetection/ Mount watching, SysInfo and model identification
    Library/         iTunesDB parsing and the lossless record tree
    MusicLibrary/    Folder scanning, SwiftData library and tag editing
    Playlists/       Playlist models and views
    Sync/            Sync planning, database editing, artwork and hash58 signing
    Updates/         Sparkle integration
SyncMyPodTests/      Unit tests and fixture builders
```

## Acknowledgements

SyncMyPod doesn't link to or bundle [libgpod](https://sourceforge.net/projects/gtkpod/), but SyncMyPod's iPod syncing code draws heavily on what libgpod documents. Many thanks to the libgpod contributors for years of work documenting how the iPod stores music.

- **hash58 signing**: `Hash58.swift` is a Swift port of libgpod's `itdb_hash58.c` by Christophe Fergeau, which builds on proof-of-concept work by wtbw. Unlike the rest of libgpod (LGPL), that file is under a BSD-style license, which is kept in the source file's header and in `SyncMyPod/Credits.html`.
- **Database and device code**: libgpod served as the reference for how the iTunesDB, ArtworkDB and Play Counts files are laid out, which artwork sizes each device uses, and how to read SysInfoExtended over USB.

## License

SyncMyPod is released under the [MIT License](LICENSE). Copyright © 2026 Major Talent Studios, LLC.

`Hash58.swift` is excluded and stays under its original BSD-style license (see [Acknowledgements](#acknowledgements)).

iTunes and iPod are trademarks of Apple Inc. SyncMyPod is not affiliated with Apple.
