import Foundation

nonisolated extension NanoLibraryRows {
    private static let albumFieldOrder = 1

    func containers() -> SQLiteTableRows {
        let kindsByPID = Dictionary(snapshot.items.map { ($0.pid, NanoMediaKind(mediaType: $0.mediaType).rawValue) },
                                    uniquingKeysWith: { first, _ in first })
        return SQLiteTableRows(table: "container", records: snapshot.playlists.map { playlist in
            let created = NanoTimestamp.seconds(fromLocal: playlist.dateCreated)
            return [("pid", .id(playlist.pid)), ("distinguished_kind", .int(playlist.distinguishedKind)),
                    ("date_created", .int(created)), ("date_modified", .int(created)), ("name", .text(playlist.name)),
                    ("name_order", .int(catalog.playlists.order(of: playlist.name))), ("parent_pid", .int(0)),
                    ("media_kinds", .int(mediaKinds(of: playlist, kindsByPID: kindsByPID))), ("workout_template_id", .int(0)),
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

    /// A user playlist is marked with the kinds of what it holds, so an audiobook's playlist lists its parts
    /// rather than being taken for a list of songs; one of songs, or an empty one, stays a music list.
    private func mediaKinds(of playlist: NanoLibraryPlaylist, kindsByPID: [UInt64: Int]) -> Int {
        guard !playlist.isMaster, !playlist.isPodcasts, playlist.distinguishedKind == 0 else { return playlist.mediaKinds }
        let kinds = playlist.itemPIDs.compactMap { kindsByPID[$0] }.reduce(0, |)
        return kinds == 0 ? playlist.mediaKinds : kinds
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
