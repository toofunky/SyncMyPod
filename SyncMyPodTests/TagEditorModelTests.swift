import Foundation
import Testing
@testable import SyncMyPod

@MainActor
struct TagEditorModelTests {
    private static func track(_ title: String, album: String, number: Int, count: Int) -> LibraryTrack {
        let track = LibraryTrack(filePath: "/Music/\(title).m4a")
        track.title = title
        track.album = album
        track.trackNumber = number
        track.trackCount = count
        return track
    }

    private let tracks = [track("One", album: "Record", number: 1, count: 0),
                          track("Two", album: "Record", number: 2, count: 0)]

    @Test func showsSharedValuesAndMarksDifferingOnesMixed() {
        let model = TagEditorModel(tracks: tracks)
        #expect(model.originals[.album] == .common("Record"))
        #expect(model.originals[.title] == .mixed)
        #expect(model.values[.title] == "" && model.placeholder(for: .title) == "Mixed")
        #expect(model.originals[.trackCount] == .common(""))
        #expect(!model.hasChanges)
    }

    @Test func changesOnlyTheEditedFields() {
        let model = TagEditorModel(tracks: tracks)
        model.values[.album] = "Record (Deluxe)"
        model.values[.trackCount] = "12"

        #expect(model.edits == [.album: "Record (Deluxe)", .trackCount: "12"])
        let changes = TagChanges(edits: model.edits, artwork: model.artworkChange, applyingTo: tracks[1])
        #expect(changes == TagChanges(album: "Record (Deluxe)", track: TagNumberPair(number: 2, count: 12)))
    }

    @Test func emptySortFieldsShowTheGeneratedNameWithoutSavingIt() {
        let track = Self.track("One", album: "The Record", number: 1, count: 0)
        let model = TagEditorModel(tracks: [track])
        #expect(model.values[.sortAlbum] == "" && model.placeholder(for: .sortAlbum) == "Record")
        #expect(model.placeholder(for: .sortTitle) == "One")
        #expect(!model.hasChanges)

        model.values[.sortAlbum] = "Record, The"
        let changes = TagChanges(edits: model.edits, artwork: model.artworkChange, applyingTo: track)
        #expect(changes == TagChanges(sortAlbum: "Record, The"))
    }

    @Test func revertDiscardsEditsAndArtwork() {
        let model = TagEditorModel(tracks: tracks)
        model.values[.genre] = "Rock"
        model.removeArtwork()
        #expect(model.hasChanges)

        model.revert()
        #expect(!model.hasChanges)
    }

    @Test func editsLyricsOnlyForOneSongOnceTheyAreRead() async {
        let several = TagEditorModel(tracks: tracks)
        await several.loadLyrics()
        several.lyrics = "Lights go out"
        #expect(!several.canEditLyrics && several.lyricsEdit == nil && !several.hasChanges)

        let model = TagEditorModel(tracks: [tracks[0]])
        model.lyrics = "Typed too early"
        #expect(model.lyricsEdit == nil)

        await model.loadLyrics()
        #expect(model.canEditLyrics && model.originalLyrics == "" && model.lyrics == "")
        model.lyrics = "Lights go out"
        #expect(model.lyricsEdit == "Lights go out" && model.hasChanges)
        let changes = TagChanges(edits: model.edits, artwork: model.artworkChange, lyrics: model.lyricsEdit,
                                 applyingTo: tracks[0])
        #expect(changes == TagChanges(lyrics: "Lights go out"))

        model.revert()
        #expect(model.lyrics == "" && !model.hasChanges)
    }

    @Test func rejectsArtworkThatIsNotJPEGOrPNG() {
        let model = TagEditorModel(tracks: tracks)
        #expect(!model.replaceArtwork(with: Data("GIF89a".utf8)))
        #expect(model.artworkChange == .keep)
    }
}
