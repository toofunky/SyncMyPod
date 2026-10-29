import Foundation

/// The SQLite `media_kind` for an iTunesDB media type, and the `is_*` flag columns it sets.
nonisolated enum NanoMediaKind: Int, CaseIterable, Sendable {
    case song = 1
    case movie = 2
    case podcast = 4
    case audiobook = 8
    case musicVideo = 32
    case tvShow = 64
    case ringtone = 0x4000

    /// The `is_*` columns in the order `columns` lists them.
    static let flagColumns = ["is_song", "is_movie", "is_podcast", "is_audio_book", "is_music_video", "is_tv_show",
                              "is_ringtone"]

    init(mediaType: UInt32) {
        switch mediaType {
        case 0x02: self = .movie
        case 0x04, 0x06: self = .podcast
        case 0x08: self = .audiobook
        case 0x20: self = .musicVideo
        case 0x40: self = .tvShow
        case 0x4000: self = .ringtone
        default: self = .song
        }
    }

    var flags: [SQLiteValue] {
        Self.allCases.map { .bool($0 == self) }
    }
}
