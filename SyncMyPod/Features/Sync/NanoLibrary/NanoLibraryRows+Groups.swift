import Foundation

nonisolated extension NanoLibraryRows {
    private static let groupKind = 2
    private static let mp3FileType: UInt32 = 0x4D50_3320
    private static let defaultGaplessHeuristic = 1

    func audioFormats() -> SQLiteTableRows {
        SQLiteTableRows(table: "avformat_info", records: snapshot.items.map { item in
            [("item_pid", .id(item.pid)), ("sub_id", .int(0)), ("audio_format", .int(Self.audioFormat(of: item))),
             ("bit_rate", .int(item.bitrate)), ("channels", .int(0)), ("sample_rate", .real(Double(item.sampleRate))),
             ("duration", .int(item.sampleCount)), ("gapless_heuristic_info", .int(Self.defaultGaplessHeuristic)),
             ("gapless_encoding_delay", .int(item.encoderDelay)), ("gapless_encoding_drain", .int(item.encoderDrain)),
             ("gapless_last_frame_resynch", .int(item.lastFrameResync)), ("analysis_inhibit_flags", .int(0)),
             ("audio_fingerprint", .int(0)), ("volume_normalization_energy", .int(item.volumeNormalization))]
        })
    }

    func albums() -> SQLiteTableRows {
        let grouped = Dictionary(grouping: snapshot.items.filter { catalog.albumPID(of: $0) != nil }) {
            catalog.albumPID(of: $0)!
        }
        return SQLiteTableRows(table: "album", records: grouped.sorted { $0.key < $1.key }.map { pid, tracks in
            let first = tracks.min { ($0.discNumber, $0.trackNumber) < ($1.discNumber, $1.trackNumber) } ?? tracks[0]
            return [("pid", .id(pid)), ("kind", .int(Self.groupKind)), ("artwork_status", .int(0)),
                    ("artwork_item_pid", .id((tracks.first { $0.artworkID != 0 } ?? first).pid)),
                    ("artist_pid", catalog.albumArtistPID(of: first).map(SQLiteValue.id) ?? .null), ("user_rating", .int(0)),
                    ("name", .optionalText(first.string(.album))), ("name_order", .int(catalog.albums.order(of: first.sortAlbum))),
                    ("all_compilations", .bool(tracks.allSatisfy(\.isCompilation))), ("feed_url", .null),
                    ("season_number", .int(0))]
        })
    }

    func artists() -> SQLiteTableRows {
        let byName = Dictionary(snapshot.items.compactMap { item in item.albumArtistName.map { ($0, item) } },
                                uniquingKeysWith: { first, _ in first })
        return SQLiteTableRows(table: "artist", records: byName.sorted { $0.key < $1.key }.compactMap { name, item in
            guard let pid = catalog.artistPIDs[name] else { return nil }
            return [("pid", .id(pid)), ("kind", .int(Self.groupKind)), ("artwork_status", .int(0)),
                    ("artwork_album_pid", .int(0)), ("name", .text(name)),
                    ("name_order", .int(catalog.albumArtists.order(of: item.albumArtistSortKey))),
                    ("sort_name", .optionalText(item.albumArtistSortKey))]
        })
    }

    func composers() -> SQLiteTableRows {
        let byName = Dictionary(snapshot.items.compactMap { item in item.string(.composer).map { ($0, item) } },
                                uniquingKeysWith: { first, _ in first })
        return SQLiteTableRows(table: "composer", records: byName.sorted { $0.key < $1.key }.map { name, item in
            [("pid", .int(catalog.composerPID(of: item))), ("name", .text(name)),
             ("name_order", .int(catalog.composers.order(of: item.sortComposer))),
             ("sort_name", .optionalText(item.sortComposer))]
        })
    }

    func genres() -> SQLiteTableRows {
        let names = Set(snapshot.items.compactMap { $0.string(.genre) }).sorted()
        return SQLiteTableRows(table: "genre_map", records: names.map { name in
            [("id", .int(catalog.genres.position(of: name))), ("genre", .text(name)),
             ("genre_order", .int(catalog.genres.position(of: name)))]
        })
    }

    func locationKinds() -> SQLiteTableRows {
        SQLiteTableRows(table: "location_kind_map", records: catalog.kindIDs.sorted { $0.value < $1.value }.map {
            [("id", .int($0.value)), ("kind", .text($0.key))]
        })
    }

    /// 301 MP3, 502 AAC and 601 Apple Lossless, as iTunes writes them.
    private static func audioFormat(of item: NanoLibraryItem) -> Int {
        if item.fileTypeCode == mp3FileType { return 301 }
        return item.string(.fileType)?.localizedCaseInsensitiveContains("lossless") == true ? 601 : 502
    }
}
