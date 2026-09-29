import Foundation

/// Adds, updates and removes tracks in a parsed iTunesDB tree, keeping every record it doesn't touch byte-identical.
nonisolated struct ITunesDBEditor {
    private static let databaseIDOffset = 0x70
    private static let playlistItemCountOffset = 0x10
    private static let playlistSections: [ITunesDBSectionType] = [.playlists, .podcasts]

    private(set) var root: ITunesDBRecord
    private var ids: ITunesDBIDAllocator
    private var databaseIDs: Set<UInt64>
    private let trackBuilder: TrackRecordBuilder
    private var hasChanges = false

    init(root: ITunesDBRecord) throws {
        guard let tracks = Self.list(in: root, section: .tracks) else { throw IPodSyncError.missingTrackList }
        guard Self.playlistSections.contains(where: {
            Self.list(in: root, section: $0)?.children.contains(where: \.isMasterPlaylist) == true
        }) else {
            throw IPodSyncError.missingMasterPlaylist
        }
        self.root = root
        ids = ITunesDBIDAllocator(root: root)
        databaseIDs = Set(tracks.children.map { $0.uint64(at: Self.databaseIDOffset) })
        let existingHeaderLength = tracks.children.first?.header.count ?? 0
        trackBuilder = TrackRecordBuilder(headerLength: max(existingHeaderLength,
                                                            TrackRecordBuilder.minimumHeaderLength))
    }

    /// Appends the track to the track list and master playlist, returning its new database ID.
    mutating func addTrack(_ draft: ITunesTrackDraft) -> UInt64 {
        let trackID = ids.allocate()
        let databaseID = makeDatabaseID()
        let albumID = albumID(for: draft)
        let mhit = trackBuilder.build(draft, id: trackID, databaseID: databaseID, albumID: albumID)
        modifyList(.tracks) { $0.children.append(mhit) }
        let item = PlaylistItemRecordBuilder.build(itemID: ids.allocate(), trackID: trackID,
                                                   databaseID: databaseID, dateAdded: draft.dateAdded)
        for section in Self.playlistSections {
            modifyMasterPlaylist(section) { playlist in
                playlist.children.append(item)
                playlist.set(playlist.uint32(at: Self.playlistItemCountOffset) + 1,
                             at: Self.playlistItemCountOffset)
            }
        }
        hasChanges = true
        return databaseID
    }

    /// Removes the tracks from the track list, every playlist and the album list, returning their file locations.
    mutating func removeTracks(databaseIDs: Set<UInt64>) -> [String] {
        let locations = ITunesDBTrackRemover.remove(databaseIDs, from: &root)
        if !locations.isEmpty { hasChanges = true }
        return locations
    }

    /// Rewrites the track in place, keeping its IDs, play counts and playlist entries. Returns its previous
    /// file location; `nil` if it had none or isn't in the database.
    mutating func updateTrack(databaseID: UInt64, with draft: ITunesTrackDraft, keepingArtwork: Bool) -> String? {
        guard ITunesDBTrackUpdater.contains(databaseID, in: root) else { return nil }
        let albumID = albumID(for: draft)
        hasChanges = true
        return ITunesDBTrackUpdater.update(databaseID, with: draft, albumID: albumID, keepingArtwork: keepingArtwork,
                                           builder: trackBuilder, in: &root)
    }

    /// Writes the playlists, replacing any with the same ID and removing those in `removing`.
    mutating func replacePlaylists(_ drafts: [ITunesPlaylistDraft], removing ids: Set<UInt64>) {
        ITunesDBPlaylistWriter.replace(drafts, removing: ids, in: &root, allocator: &self.ids)
        hasChanges = true
    }

    /// Folds the iPod's Play Counts into the tracks; `false` if the entries don't match the track list.
    mutating func mergePlayCounts(_ entries: [PlayCountEntry]) -> Bool {
        guard PlayCountsMerger.merge(entries, into: &root) else { return false }
        hasChanges = true
        return true
    }

    /// The database bytes, with the master playlist's browse indexes rebuilt if tracks changed.
    func serialized() throws -> Data {
        guard hasChanges else { return root.serialized() }
        let database = try ITunesDBParser(data: root.serialized()).parse()
        guard let master = database.masterPlaylist else { throw IPodSyncError.missingMasterPlaylist }
        let tracksByID = Dictionary(database.tracks.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let index = LibraryIndexRecordBuilder(tracks: master.trackIDs.compactMap { tracksByID[$0] }).records()
        var indexed = self
        for section in Self.playlistSections {
            indexed.modifyMasterPlaylist(section) { Self.replaceIndexRecords(in: &$0, with: index) }
        }
        return indexed.root.serialized()
    }

    private mutating func albumID(for draft: ITunesTrackDraft) -> UInt32 {
        guard let albums = Self.list(in: root, section: .albums) else { return 0 }
        let existing = albums.children.first {
            $0.string(ofType: AlbumItemRecordBuilder.albumType) == draft.album
                && $0.string(ofType: AlbumItemRecordBuilder.artistType) == draft.albumListArtist
        }
        if let existing { return existing.uint32(at: 0x10) }
        let albumID = ids.allocate()
        let mhia = AlbumItemRecordBuilder.build(albumID: albumID, album: draft.album, artist: draft.albumListArtist)
        modifyList(.albums) { $0.children.append(mhia) }
        return albumID
    }

    private mutating func makeDatabaseID() -> UInt64 {
        var candidate = UInt64.random(in: 1...UInt64.max)
        while databaseIDs.contains(candidate) { candidate = UInt64.random(in: 1...UInt64.max) }
        databaseIDs.insert(candidate)
        return candidate
    }

    private mutating func modifyList(_ section: ITunesDBSectionType, _ change: (inout ITunesDBRecord) -> Void) {
        guard let index = root.children.firstIndex(where: { $0.isSection(section) }),
              !root.children[index].children.isEmpty else { return }
        change(&root.children[index].children[0])
    }

    private mutating func modifyMasterPlaylist(_ section: ITunesDBSectionType,
                                               _ change: (inout ITunesDBRecord) -> Void) {
        modifyList(section) { list in
            guard let master = list.children.firstIndex(where: \.isMasterPlaylist) else { return }
            change(&list.children[master])
        }
    }

    private static func replaceIndexRecords(in playlist: inout ITunesDBRecord, with index: [ITunesDBRecord]) {
        let indexTypes = [LibraryIndexRecordBuilder.indexType, LibraryIndexRecordBuilder.jumpTableType]
        let mhods = playlist.children.filter { $0.tag == "mhod" && !indexTypes.contains($0.recordType) } + index
        playlist.children = mhods + playlist.children.filter { $0.tag != "mhod" }
        playlist.set(UInt32(mhods.count), at: 0x0C)
    }

    private static func list(in root: ITunesDBRecord, section: ITunesDBSectionType) -> ITunesDBRecord? {
        root.children.first { $0.isSection(section) }?.children.first
    }
}
