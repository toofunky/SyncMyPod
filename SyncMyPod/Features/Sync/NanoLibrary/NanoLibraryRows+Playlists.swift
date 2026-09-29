import Foundation

nonisolated extension NanoLibraryRows {
    private static let albumFieldOrder = 1

    func containers() -> SQLiteTableRows {
        SQLiteTableRows(table: "container", records: snapshot.playlists.map { playlist in
            let created = NanoTimestamp.seconds(fromLocal: playlist.dateCreated)
            return [("pid", .id(playlist.pid)), ("distinguished_kind", .int(playlist.distinguishedKind)),
                    ("date_created", .int(created)), ("date_modified", .int(created)), ("name", .text(playlist.name)),
                    ("name_order", .int(catalog.playlists.order(of: playlist.name))), ("parent_pid", .int(0)),
                    ("media_kinds", .bool(playlist.holdsMusic)), ("workout_template_id", .int(0)),
                    ("is_hidden", .bool(playlist.isHidden)), ("smart_is_folder", .int(0))]
        })
    }

    func containerItems() -> SQLiteTableRows {
        SQLiteTableRows(table: "item_to_container", records: snapshot.playlists.flatMap { playlist in
            playlist.itemPIDs.enumerated().map { position, pid in
                [("item_pid", .id(pid)), ("container_pid", .id(playlist.pid)), ("physical_order", .int(position)),
                 ("shuffle_order", .null)]
            }
        })
    }

    /// Defaults for playlists the device has no saved view state for yet.
    func containerViewStates() -> SQLiteTableRows {
        SQLiteTableRows(table: "container_ui", records: snapshot.playlists.map { playlist in
            [("container_pid", .id(playlist.pid)), ("play_order", .int(1)), ("is_reversed", .int(0)),
             ("album_field_order", .int(Self.albumFieldOrder)), ("repeat_mode", .int(0)), ("shuffle_items", .int(0)),
             ("has_been_shuffled", .int(0))]
        })
    }
}
