import Foundation

nonisolated struct ITunesDBParser {
    private let reader: BinaryReader

    init(data: Data) {
        reader = BinaryReader(data: data)
    }

    func parse() throws -> ITunesDatabase {
        try reader.expectTag("mhbd", at: 0)
        var tracks: [ITunesTrack] = []
        var playlists: [ITunesPlaylist] = []
        var cursor = try reader.int(at: 0x04)
        for _ in 0..<(try reader.int(at: 0x14)) {
            try reader.expectTag("mhsd", at: cursor)
            let listOffset = cursor + (try reader.int(at: cursor + 0x04))
            switch ITunesDBSectionType(rawValue: try reader.uint32(at: cursor + 0x0C)) {
            case .tracks: tracks = try parseTracks(at: listOffset)
            case .playlists: playlists = try parsePlaylists(at: listOffset)
            default: break
            }
            cursor += try reader.recordLength(at: cursor)
        }
        return try ITunesDatabase(version: reader.uint32(at: 0x10), databaseID: reader.uint64(at: 0x18),
                                  tracks: tracks, playlists: playlists)
    }

    private func parseTracks(at offset: Int) throws -> [ITunesTrack] {
        let trackParser = TrackRecordParser(reader: reader)
        return try RecordListParser(reader: reader)
            .parse(listTag: "mhlt", at: offset, record: trackParser.parse(at:))
    }

    private func parsePlaylists(at offset: Int) throws -> [ITunesPlaylist] {
        let playlistParser = PlaylistRecordParser(reader: reader)
        return try RecordListParser(reader: reader)
            .parse(listTag: "mhlp", at: offset, record: playlistParser.parse(at:))
    }
}
