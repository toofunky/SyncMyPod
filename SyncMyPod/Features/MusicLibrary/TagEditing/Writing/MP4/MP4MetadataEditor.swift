import Foundation

/// Applies `TagChanges` to the `ilst` inside a `moov` box, creating `udta/meta/ilst` when they're missing.
nonisolated enum MP4MetadataEditor {
    static func apply(_ changes: TagChanges, to moov: inout MP4Box) {
        moov.withChild(.udta, orMake: { MP4Box(type: .udta, children: []) }) { udta in
            udta.withChild(.meta, orMake: makeMeta) { meta in
                meta.withChild(.ilst, orMake: { MP4Box(type: .ilst, children: []) }) { ilst in
                    var items = ilst.children ?? []
                    applyText(changes, to: &items)
                    applyNumbers(changes, to: &items)
                    applyArtwork(changes.artwork, to: &items)
                    ilst.children = items
                }
            }
        }
    }

    private static func applyText(_ changes: TagChanges, to items: inout [MP4Box]) {
        let fields: [(FourCC, String?)] = [
            (.songName, changes.title), (.artist, changes.artist), (.album, changes.album),
            (.albumArtist, changes.albumArtist), (.userGenre, changes.genre),
            (.releaseDate, changes.year.map { $0 > 0 ? String($0) : "" }),
        ]
        for case let (type, value?) in fields {
            if type == .userGenre { items.removeAll { $0.type == .standardGenre } }
            set(type, value.isEmpty ? nil : ILSTItemBuilder.text(type, value), in: &items)
        }
    }

    private static func applyNumbers(_ changes: TagChanges, to items: inout [MP4Box]) {
        for case let (type, pair?) in [(FourCC.trackNumber, changes.track), (.discNumber, changes.disc)] {
            let isEmpty = pair.number == 0 && pair.count == 0
            set(type, isEmpty ? nil : ILSTItemBuilder.numberPair(type, pair), in: &items)
        }
    }

    private static func applyArtwork(_ change: ArtworkChange, to items: inout [MP4Box]) {
        switch change {
        case .keep: return
        case .remove: set(.coverArt, nil, in: &items)
        case .replace(let image):
            guard let type = ArtworkImageType(data: image) else { return }
            set(.coverArt, ILSTItemBuilder.coverArt(image, type: type), in: &items)
        }
    }

    /// Replaces the item of `type` where it stood, or appends it; `nil` removes it.
    private static func set(_ type: FourCC, _ item: MP4Box?, in items: inout [MP4Box]) {
        let index = items.firstIndex { $0.type == type }
        items.removeAll { $0.type == type }
        guard let item else { return }
        items.insert(item, at: min(index ?? items.count, items.count))
    }

    /// The `hdlr` iTunes writes: full-box header, pre-defined, `mdir`, `appl`, reserved and an empty name.
    private static func makeMeta() -> MP4Box {
        var handler = Data(count: 8)
        handler.appendBigEndian(FourCC("mdir").rawValue)
        handler.appendBigEndian(FourCC("appl").rawValue)
        handler.append(Data(count: 9))
        return MP4Box(type: .meta, prefix: Data(count: 4),
                      children: [MP4Box(type: .hdlr, payload: handler), MP4Box(type: .ilst, children: [])])
    }
}
