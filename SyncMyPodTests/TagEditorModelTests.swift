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

    @Test func revertDiscardsEditsAndArtwork() {
        let model = TagEditorModel(tracks: tracks)
        model.values[.genre] = "Rock"
        model.removeArtwork()
        #expect(model.hasChanges)

        model.revert()
        #expect(!model.hasChanges)
    }

    @Test func rejectsArtworkThatIsNotJPEGOrPNG() {
        let model = TagEditorModel(tracks: tracks)
        #expect(!model.replaceArtwork(with: Data("GIF89a".utf8)))
        #expect(model.artworkChange == .keep)
    }
}
