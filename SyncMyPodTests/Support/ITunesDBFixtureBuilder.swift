import Foundation
@testable import SyncMyPod

/// Assembles a minimal but structurally valid iTunesDB, laid out the way iTunes writes it for 5G/classic iPods.
struct ITunesDBFixtureBuilder {
    var tracks: [FixtureTrack] = []
    var playlists: [FixturePlaylist] = []
    var usesUTF8Strings = false
    var includesAlbumSection = false
    var includesRawSection = false
    var includesPodcastSection = false

    func build() -> Data {
        var sections = [
            section(type: 1, list: list("mhlt", headerLength: 0x5C, items: tracks.map(trackRecord))),
            section(type: 2, list: list("mhlp", headerLength: 0x5C, items: playlists.map(playlistRecord)))
        ]
        if includesAlbumSection {
            sections.append(section(type: 4, list: list("mhla", headerLength: 0x5C, items: [])))
        }
        if includesPodcastSection {
            sections.append(section(type: 3, list: list("mhlp", headerLength: 0x5C,
                                                        items: playlists.map(playlistRecord))))
        }
        if includesRawSection {
            sections.append(section(type: 9, list: Data("13b7d9f0c2a4e6f8".utf8)))
        }
        var database = record("mhbd", headerLength: 0xBC, children: sections.reduce(Data(), +))
        database.write(UInt32(1), at: 0x0C)
        database.write(UInt32(0x19), at: 0x10)
        database.write(UInt32(sections.count), at: 0x14)
        database.write(UInt64(0x0123_4567_89AB_CDEF), at: 0x18)
        return database
    }

    private func trackRecord(_ track: FixtureTrack) -> Data {
        let fields = [(1, track.title), (2, track.location), (3, track.album), (4, track.artist)]
            .map { (UInt32($0.0), $0.1) } + track.extraStrings.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
        let strings = fields.map { stringRecord(type: $0.0, value: $0.1) }
        var mhit = record("mhit", headerLength: 0x184, children: strings.reduce(Data(), +))
        mhit.write(UInt32(strings.count), at: 0x0C)
        mhit.write(track.id, at: 0x10)
        mhit.write(UInt8(80), at: 0x1F)
        mhit.write(track.durationMilliseconds, at: 0x28)
        mhit.write(track.year, at: 0x34)
        mhit.write(UInt32(44_100) << 16, at: 0x3C)
        mhit.write(track.playCount, at: 0x50)
        mhit.write(track.dateAddedMacSeconds, at: 0x68)
        mhit.write(UInt64(track.id) * 1_000, at: 0x70)
        mhit.write(UInt32(1), at: 0xD0)
        return mhit
    }

    private func playlistRecord(_ playlist: FixturePlaylist) -> Data {
        let strings = [stringRecord(type: 1, value: playlist.name), opaqueRecord(type: 100)]
        let items = playlist.trackIDs.map(playlistItemRecord)
        var mhyp = record("mhyp", headerLength: 0x6C, children: (strings + items).reduce(Data(), +))
        mhyp.write(UInt32(strings.count), at: 0x0C)
        mhyp.write(UInt32(items.count), at: 0x10)
        mhyp.write(UInt8(playlist.isMaster ? 1 : 0), at: 0x14)
        mhyp.write(playlist.id, at: 0x1C)
        return mhyp
    }

    private func playlistItemRecord(trackID: UInt32) -> Data {
        var mhip = record("mhip", headerLength: 0x4C, children: opaqueRecord(type: 100))
        mhip.write(UInt32(1), at: 0x0C)
        mhip.write(trackID, at: 0x18)
        return mhip
    }

    private func stringRecord(type: UInt32, value: String) -> Data {
        let payload = usesUTF8Strings ? Data(value.utf8) : value.data(using: .utf16LittleEndian)!
        var mhod = record("mhod", headerLength: 0x18, children: Data(count: 0x10) + payload)
        mhod.write(type, at: 0x0C)
        mhod.write(UInt32(usesUTF8Strings ? 2 : 1), at: 0x18)
        mhod.write(UInt32(payload.count), at: 0x1C)
        return mhod
    }

    private func opaqueRecord(type: UInt32) -> Data {
        var mhod = record("mhod", headerLength: 0x18, children: Data(count: 0x14))
        mhod.write(type, at: 0x0C)
        return mhod
    }

    private func section(type: UInt32, list: Data) -> Data {
        var mhsd = record("mhsd", headerLength: 0x60, children: list)
        mhsd.write(type, at: 0x0C)
        return mhsd
    }

    private func list(_ tag: String, headerLength: Int, items: [Data]) -> Data {
        var header = record(tag, headerLength: headerLength, children: Data())
        header.write(UInt32(items.count), at: 0x08)
        return items.reduce(header, +)
    }

    private func record(_ tag: String, headerLength: Int, children: Data) -> Data {
        var header = Data(count: headerLength)
        header.replaceSubrange(0..<4, with: Data(tag.utf8))
        header.write(UInt32(headerLength), at: 0x04)
        header.write(UInt32(headerLength + children.count), at: 0x08)
        return header + children
    }
}
