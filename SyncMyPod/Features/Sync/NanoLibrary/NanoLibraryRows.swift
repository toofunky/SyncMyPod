import Foundation

/// Builds the base rows iTunes writes to the nano's SQLite files, before the device's post-process commands.
nonisolated struct NanoLibraryRows: Sendable {
    typealias Record = SQLiteTableRows.Record

    static let seriesNameOrder = 100

    let catalog: NanoLibraryCatalog

    var snapshot: NanoLibrarySnapshot { catalog.snapshot }

    func libraryTables(geniusCUID: String?) -> [SQLiteTableRows] {
        [versionInfo(), dbInfo(geniusCUID: geniusCUID), items(), audioFormats(), albums(), artists(), composers(),
         genres(), locationKinds(), containers(), containerItems()]
    }

    private func versionInfo() -> SQLiteTableRows {
        SQLiteTableRows(table: "version_info", records: [[
            ("id", .int(1)), ("major", .int(1)), ("minor", .int(snapshot.databaseVersion)), ("compatibility", .int(0)),
            ("update_level", .int(0)), ("device_update_level", .int(0)), ("platform", .int(1))
        ]])
    }

    private func dbInfo(geniusCUID: String?) -> SQLiteTableRows {
        SQLiteTableRows(table: "db_info", records: [[
            ("pid", .id(snapshot.libraryPID)), ("primary_container_pid", snapshot.masterPlaylist.map { .id($0.pid) } ?? .null),
            ("media_folder_url", .null), ("audio_language", .int(-1)), ("subtitle_language", .int(-1)),
            ("genius_cuid", .optionalText(geniusCUID)), ("bib", .null), ("rib", .null)
        ]])
    }

    private func items() -> SQLiteTableRows {
        SQLiteTableRows(table: "item", records: snapshot.items.map { item in
            [("pid", .id(item.pid)), ("media_kind", .int(NanoMediaKind(mediaType: item.mediaType).rawValue))]
                + zip(NanoMediaKind.flagColumns, NanoMediaKind(mediaType: item.mediaType).flags).map { ($0, $1) }
                + itemNumbers(item) + itemLinks(item) + itemStrings(item) + itemOrders(item)
        })
    }

    private func itemNumbers(_ item: NanoLibraryItem) -> Record {
        [("date_modified", .int(NanoTimestamp.seconds(fromLocal: item.dateModified))), ("year", .int(item.year)),
         ("is_compilation", .bool(item.isCompilation)), ("artwork_status", .int(item.artworkID == 0 ? 2 : 1)),
         ("artwork_cache_id", .int(item.artworkID)), ("total_time_ms", .real(Double(item.durationMS))),
         ("track_number", .int(item.trackNumber)), ("track_count", .int(item.trackCount)),
         ("disc_number", .int(item.discNumber)), ("disc_count", .int(item.discCount)), ("bpm", .int(item.bpm)),
         ("relative_volume", .int(0))]
    }

    private func itemLinks(_ item: NanoLibraryItem) -> Record {
        [("genre_id", .int(catalog.genreID(of: item))), ("album_pid", catalog.albumPID(of: item).map(SQLiteValue.id) ?? .int(0)),
         ("artist_pid", catalog.artistPID(of: item).map(SQLiteValue.id) ?? .int(0)),
         ("composer_pid", .int(catalog.composerPID(of: item)))]
    }

    private func itemStrings(_ item: NanoLibraryItem) -> Record {
        let plain: [(String, ITunesStringField)] = [("title", .title), ("artist", .artist), ("album", .album),
                                                     ("album_artist", .albumArtist), ("composer", .composer),
                                                     ("comment", .comment), ("grouping", .grouping)]
        return plain.map { ($0.0, .optionalText(item.string($0.1))) } + [
            ("sort_title", .optionalText(item.sortTitle)), ("sort_artist", .optionalText(item.sortArtist)),
            ("sort_album", .optionalText(item.sortAlbum)), ("sort_album_artist", .optionalText(item.sortAlbumArtist)),
            ("sort_composer", .optionalText(item.sortComposer))
        ]
    }

    private func itemOrders(_ item: NanoLibraryItem) -> Record {
        [("title_order", .int(catalog.titles.order(of: item.sortTitle))),
         ("artist_order", .int(catalog.artists.order(of: item.sortArtist))),
         ("album_order", .int(catalog.albums.order(of: item.sortAlbum))),
         ("genre_order", .int(catalog.genres.order(of: item.string(.genre)))),
         ("composer_order", .int(catalog.composers.order(of: item.sortComposer))),
         ("album_artist_order", .int(catalog.albumArtists.order(of: item.albumArtistSortKey))),
         ("series_name_order", .int(Self.seriesNameOrder))]
    }
}
