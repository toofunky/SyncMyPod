import Foundation
import Testing
@testable import SyncMyPod

struct FolderOverlapErrorTests {
    private let folders: [MediaFolderKind: String] = [.music: "/Music", .podcasts: "/Podcasts",
                                                      .audiobooks: "/Books"]

    @Test func separateFoldersDoNotOverlap() {
        #expect(FolderOverlapError.check("/Other", as: .podcasts, against: folders) == nil)
    }

    @Test func folderInsideMusicOverlapsIt() {
        let error = FolderOverlapError.check("/Music/Podcasts", as: .podcasts, against: folders)
        #expect(error == FolderOverlapError(chosen: .podcasts, existing: .music, existingPath: "/Music"))
    }

    @Test func folderAroundAnotherOverlapsIt() {
        let error = FolderOverlapError.check("/", as: .audiobooks, against: [.podcasts: "/Podcasts"])
        #expect(error?.existing == .podcasts)
    }

    @Test func aFolderIsNotCheckedAgainstItsOwnKind() {
        #expect(FolderOverlapError.check("/Podcasts/New", as: .podcasts, against: folders) == nil)
    }

    @Test func similarNamesDoNotOverlap() {
        #expect(FolderOverlapError.check("/Music Podcasts", as: .podcasts, against: folders) == nil)
    }

    @Test func messageNamesBothFoldersAndWhatScanningWouldDo() {
        let error = FolderOverlapError(chosen: .music, existing: .audiobooks, existingPath: "/Books")
        #expect(error.localizedDescription == "Your music folder can't be inside or around your audiobook folder "
            + "“/Books”, or scanning it would add every book to your music library. Choose a folder outside it.")
    }

    @Test func podcastAndAudiobookFoldersWarnAboutEpisodesListedAsBooks() {
        let error = FolderOverlapError(chosen: .podcasts, existing: .audiobooks, existingPath: "/Books")
        #expect(error.localizedDescription.contains("list every episode as an audiobook"))
    }
}
