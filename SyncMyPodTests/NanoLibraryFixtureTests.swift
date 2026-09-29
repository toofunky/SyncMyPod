import Foundation
import Testing
@testable import SyncMyPod

/// Regenerates a nano's SQLite library from the iTunesCDB iTunes wrote alongside it, and compares the two.
@Suite(.enabled(if: RealDeviceFixture.compressedDatabase != nil && RealDeviceFixture.nanoSysInfoExtended != nil
                && RealDeviceFixture.nanoLibraryFolder != nil && RealDeviceFixture.compressedDatabaseFireWireID != nil,
                "No real nano fixtures present"))
struct NanoLibraryFixtureTests {
    private let expected: SQLiteConnection
    private let generated: SQLiteConnection
    private let generatedFolder: URL
    private let signer: HashAB

    init() throws {
        let folder = try #require(RealDeviceFixture.nanoLibraryFolder)
        signer = HashAB(fireWireID: try #require(FireWireID(hexString: RealDeviceFixture.compressedDatabaseFireWireID ?? "")))
        let commands = try #require(NanoPostProcessCommands(sysInfoExtended: RealDeviceFixture.nanoSysInfoExtended ?? ""))
        let database = try ITunesCDB.decompress(try #require(RealDeviceFixture.compressedDatabase))
        generatedFolder = URL.temporaryDirectory.appending(path: "NanoLibraryFixtureTests-\(UUID().uuidString)")
        try NanoLibraryWriter(commands: commands, signer: signer)
            .write(try NanoLibrarySnapshot(database: database), to: generatedFolder, carryingOverFrom: folder)
        expected = try Self.open(folder)
        generated = try Self.open(generatedFolder)
    }

    private static func open(_ folder: URL) throws -> SQLiteConnection {
        let connection = try SQLiteConnection(openingAt: folder.appending(path: NanoLibraryFile.library.fileName))
        for file in [NanoLibraryFile.locations, .dynamic] {
            let path = NanoLibraryCarryOver.escaped(folder.appending(path: file.fileName))
            try connection.execute("ATTACH DATABASE '\(path)' AS \(file.alias)")
        }
        return connection
    }

    private func values(_ sql: String, in connection: SQLiteConnection) throws -> [SQLiteValue: [SQLiteValue]] {
        Dictionary(try connection.rows(sql).map { ($0[0], Array($0.dropFirst())) }, uniquingKeysWith: { first, _ in first })
    }

    @Test func producesTheSameTablesAndIndexes() throws {
        let sql = "SELECT type, name, sql FROM sqlite_master WHERE sql IS NOT NULL ORDER BY type, name"
        #expect(try generated.rows(sql) == expected.rows(sql))
        #expect(try generated.rows("PRAGMA user_version") == expected.rows("PRAGMA user_version"))
    }

    @Test(arguments: ["title", "artist", "album", "album_artist", "composer", "sort_title", "sort_artist",
                      "sort_album", "is_compilation", "year", "total_time_ms", "track_number", "track_count",
                      "disc_number", "disc_count", "bpm", "album_pid", "artist_pid", "media_kind", "is_song",
                      "artwork_cache_id", "date_modified", "title_order", "artist_order", "album_order",
                      "album_artist_order", "composer_order", "physical_order",
                      "(SELECT genre FROM genre_map WHERE id = genre_id)",
                      "(SELECT name FROM track_artist WHERE pid = track_artist_pid)",
                      "(SELECT name FROM composer WHERE pid = composer_pid)"])
    func matchesItemColumn(_ column: String) throws {
        let sql = "SELECT pid, \(column) FROM item"
        try expectSame(sql, label: column)
    }

    @Test(arguments: [
        "SELECT item_pid, audio_format, bit_rate, sample_rate, duration, gapless_encoding_delay, gapless_encoding_drain, volume_normalization_energy FROM avformat_info",
        "SELECT item_pid, location, extension, file_size, date_created, (SELECT kind FROM location_kind_map WHERE id = kind_id) FROM locations.location",
        "SELECT item_pid, play_count_user, date_played, skip_count_user, user_rating FROM dynamic.item_stats",
        "SELECT pid, name, distinguished_kind, is_hidden, media_kinds, date_created FROM container",
        "SELECT container_pid || ':' || physical_order, item_pid FROM item_to_container",
        "SELECT pid, name, artist_pid, all_compilations, has_songs, item_count FROM album",
        "SELECT pid, name, has_songs, album_count FROM artist",
        "SELECT genre, has_music, album_count_calc FROM genre_map"
    ])
    func matchesTable(_ sql: String) throws {
        try expectSame(sql, label: sql)
    }

    @Test func signsTheChecksumBookLikeITunes() throws {
        let generatedLocations = try Data(contentsOf: generatedFolder.appending(path: NanoLibraryFile.locations.fileName))
        let generatedBook = try Data(contentsOf: generatedFolder.appending(path: LocationsChecksumBook.fileName))
        #expect(LocationsChecksumBook.isValid(generatedBook, for: generatedLocations, signer: signer))
        let folder = try #require(RealDeviceFixture.nanoLibraryFolder)
        let locations = try Data(contentsOf: folder.appending(path: NanoLibraryFile.locations.fileName))
        let book = try Data(contentsOf: folder.appending(path: LocationsChecksumBook.fileName))
        #expect(LocationsChecksumBook.isValid(book, for: locations, signer: signer))
    }

    private func expectSame(_ sql: String, label: String) throws {
        let want = try values(sql, in: expected)
        let got = try values(sql, in: generated)
        let mismatches = want.filter { got[$0.key] != $0.value }
        let extra = got.keys.filter { want[$0] == nil }
        let samples = mismatches.prefix(4).map { "\($0.key): want \($0.value) got \(got[$0.key].map { "\($0)" } ?? "nothing")" }
        #expect(mismatches.isEmpty && extra.isEmpty,
                "\(label): \(mismatches.count)/\(want.count) differ, \(extra.count) extra; \(samples.joined(separator: " | "))")
    }
}
