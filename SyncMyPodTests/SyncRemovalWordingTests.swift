import Testing
@testable import SyncMyPod

struct SyncRemovalWordingTests {
    @Test(arguments: [(3, 0, "Remove 3 songs from the iPod?"), (1, 0, "Remove 1 song from the iPod?"),
                      (0, 2, "Remove 2 episodes from the iPod?"), (2, 1, "Remove 2 songs and 1 episode from the iPod?")])
    func countsSongsAndEpisodesSeparately(_ songs: Int, _ episodes: Int, _ expected: String) {
        #expect(SyncRemovalWording.title(songs: songs, episodes: episodes, deviceKind: "iPod") == expected)
    }
}
