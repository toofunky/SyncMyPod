import SwiftData

nonisolated enum MusicLibrarySchema {
    static var models: [any PersistentModel.Type] {
        [LibraryFolder.self, LibraryTrack.self, LibraryPlaylist.self, IPodSyncSettings.self, Podcast.self,
         PodcastEpisode.self, Audiobook.self, AudiobookFile.self]
    }
}
