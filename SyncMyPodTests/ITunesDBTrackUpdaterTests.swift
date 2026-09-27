import Foundation
import Testing
@testable import SyncMyPod

struct ITunesDBTrackUpdaterTests {
    private let vertigo = FixtureTrack(id: 101, title: "Vertigo", artist: "U2", album: "How to Dismantle an Atomic Bomb",
                                       location: ":iPod_Control:Music:F07:ABCD.m4a", playCount: 7,
                                       dateAddedMacSeconds: 3_000_000_000,
                                       extraStrings: [ITunesStringField.composer.rawValue: "Bono",
                                                      ITunesStringField.sortComposer.rawValue: "Bono",
                                                      ITunesStringField.comment.rawValue: "Single",
                                                      ITunesStringField.sortArtist.rawValue: "U2, The"])
    private let retagged = ITunesTrackDraft(title: "Vertigo (Live)", artist: "U2", album: "Live in Dublin",
                                            composer: "U2", genre: "Rock", location: ":iPod_Control:Music:F02:WXYZ.m4a",
                                            fileSize: 6_000_000, trackNumber: 3, year: 2005, bitrate: 256,
                                            sampleRate: 44_100)

    private var fixture: Data {
        ITunesDBFixtureBuilder(tracks: [vertigo], playlists: [
            FixturePlaylist(id: 1, name: "iPod", isMaster: true, trackIDs: [101]),
            FixturePlaylist(id: 2, name: "Favorites", trackIDs: [101])
        ], includesAlbumSection: true).build()
    }

    private func editor(_ data: Data) throws -> ITunesDBEditor {
        try ITunesDBEditor(root: ITunesDBRecordParser(data: data).parse())
    }

    private func albumNames(in data: Data) throws -> [String?] {
        let root = try ITunesDBRecordParser(data: data).parse()
        let albums = try #require(root.children.first { $0.isSection(.albums) }?.children.first)
        return albums.children.map { $0.string(ofType: AlbumItemRecordBuilder.albumType) }
    }

    @Test func rewritesTagsAndKeepsIdentityStatisticsAndPlaylists() throws {
        var editor = try editor(fixture)
        let previous = editor.updateTrack(databaseID: 101_000, with: retagged, keepingArtwork: false)
        let database = try ITunesDBParser(data: editor.serialized()).parse()
        let track = try #require(database.tracks.first)

        #expect(previous == vertigo.location)
        #expect(database.tracks.count == 1)
        #expect(track.id == 101 && track.databaseID == 101_000)
        #expect(track.title == "Vertigo (Live)" && track.album == "Live in Dublin" && track.genre == "Rock")
        #expect(track.location == retagged.location && track.fileSize == 6_000_000 && track.trackNumber == 3)
        #expect(track.playCount == 7)
        #expect(track.dateAdded != nil)
        #expect(track.dateAdded == (try ITunesDBParser(data: fixture).parse().tracks.first?.dateAdded))
        #expect(database.userPlaylists.first?.trackIDs == [101])
    }

    @Test func keepsOtherStringsButDropsStaleSortNames() throws {
        var editor = try editor(fixture)
        _ = editor.updateTrack(databaseID: 101_000, with: retagged, keepingArtwork: false)
        let track = try #require(try ITunesDBParser(data: editor.serialized()).parse().tracks.first)
        #expect(track.strings[.comment] == "Single")
        #expect(track.strings[.composer] == "U2")
        #expect(track.strings[.sortArtist] == nil && track.strings[.sortComposer] == nil)
    }

    @Test func movesTrackToItsNewAlbumAndDropsTheEmptyOne() throws {
        var editor = try editor(fixture)
        var original = retagged
        original.album = "Original Album"
        let databaseID = editor.addTrack(original)
        #expect(try albumNames(in: editor.serialized()) == ["Original Album"])
        _ = editor.updateTrack(databaseID: databaseID, with: retagged, keepingArtwork: false)
        #expect(try albumNames(in: editor.serialized()) == ["Live in Dublin"])
    }

    @Test func keepsOrClearsTheArtworkLink() throws {
        var editor = try editor(fixture)
        var covered = retagged
        covered.artwork = ITunesTrackArtwork(imageID: 500, sourceByteCount: 1_234)
        let databaseID = editor.addTrack(covered)
        _ = editor.updateTrack(databaseID: databaseID, with: retagged, keepingArtwork: true)
        #expect(try mhit(databaseID, in: editor).uint32(at: 0x160) == 500)
        _ = editor.updateTrack(databaseID: databaseID, with: retagged, keepingArtwork: false)
        let cleared = try mhit(databaseID, in: editor)
        #expect(cleared.uint32(at: 0x160) == 0 && cleared.uint8(at: 0xA4) == 2 && cleared.uint32(at: 0x80) == 0)
    }

    @Test func unknownTrackChangesNothing() throws {
        var editor = try editor(fixture)
        #expect(editor.updateTrack(databaseID: 42, with: retagged, keepingArtwork: false) == nil)
        #expect(try editor.serialized() == fixture)
    }

    private func mhit(_ databaseID: UInt64, in editor: ITunesDBEditor) throws -> ITunesDBRecord {
        let root = try ITunesDBRecordParser(data: editor.serialized()).parse()
        let tracks = try #require(root.children.first { $0.isSection(.tracks) }?.children.first)
        return try #require(tracks.children.first { $0.uint64(at: 0x70) == databaseID })
    }
}
