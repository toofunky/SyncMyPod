import Testing
@testable import SyncMyPod

struct AudiobookGrouperTests {
    private let grouper = AudiobookGrouper(rootPath: "/Books/")

    private func file(_ path: String, album: String = "") -> AudiobookFileSummary {
        AudiobookFileSummary(path: "/Books/\(path)", album: album)
    }

    @Test func aFolderOfFilesIsOneBookNamedForItsFolders() {
        let groups = grouper.groups(for: [file("Shelley/Frankenstein/02.mp3"), file("Shelley/Frankenstein/01.mp3")])
        #expect(groups == [AudiobookGroup(key: "/Books/Shelley/Frankenstein",
                                          filePaths: ["/Books/Shelley/Frankenstein/01.mp3",
                                                      "/Books/Shelley/Frankenstein/02.mp3"],
                                          fallbackTitle: "Frankenstein", fallbackAuthor: "Shelley")])
    }

    @Test func discFoldersBelongToTheirBook() {
        let groups = grouper.groups(for: [file("Dune/CD 1/01.mp3"), file("Dune/Disc2/01.mp3")])
        #expect(groups.map(\.key) == ["/Books/Dune"])
        #expect(groups.first?.filePaths.count == 2)
        #expect(groups.first?.fallbackAuthor == "")
    }

    @Test func looseM4BFilesAreBooksOfTheirOwn() {
        let groups = grouper.groups(for: [file("Austen/Emma.m4b"), file("Austen/Persuasion.m4b")])
        #expect(groups.map(\.key) == ["/Books/Austen/Emma.m4b", "/Books/Austen/Persuasion.m4b"])
        #expect(groups.map(\.fallbackTitle) == ["Emma", "Persuasion"])
        #expect(groups.map(\.fallbackAuthor) == ["Austen", "Austen"])
    }

    @Test func aLoneM4BIsABookOfItsOwn() {
        let groups = grouper.groups(for: [file("Austen/Emma.m4b", album: "Emma")])
        #expect(groups.map(\.key) == ["/Books/Austen/Emma.m4b"])
        #expect(groups.map(\.fallbackAuthor) == ["Austen"])
    }

    @Test func m4bPartsWithOneAlbumAreOneBook() {
        let groups = grouper.groups(for: [file("Middlemarch/Part 1.m4b", album: "Middlemarch"),
                                          file("Middlemarch/Part 2.m4b", album: "Middlemarch")])
        #expect(groups.map(\.key) == ["/Books/Middlemarch"])
    }

    @Test func filesInTheAudiobookFolderItselfAreGroupedByAlbum() {
        let groups = grouper.groups(for: [file("a.mp3", album: "Ulysses"), file("b.mp3", album: "Ulysses"),
                                          file("Walden.m4b")])
        #expect(groups.map(\.key) == ["/Books/a.mp3", "/Books/Walden.m4b"])
        #expect(groups.first?.filePaths == ["/Books/a.mp3", "/Books/b.mp3"])
    }

    @Test func aFolderMixingM4BAndOtherFilesIsOneBook() {
        let groups = grouper.groups(for: [file("Book/intro.mp3"), file("Book/main.m4b")])
        #expect(groups.map(\.key) == ["/Books/Book"])
    }
}
