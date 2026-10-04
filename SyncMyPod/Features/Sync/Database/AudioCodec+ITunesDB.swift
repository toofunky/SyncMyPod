import Foundation

/// The `mhit` format fields for each codec, as iTunes and libgpod write them.
nonisolated extension AudioCodec {
    /// The four-character file type at `mhit` 0x18: `"M4A "` or `"MP3 "`.
    var iTunesFileType: UInt32 {
        self == .mp3 ? 0x4D50_3320 : 0x4D34_4120
    }

    var iTunesKind: String {
        switch self {
        case .aac: "AAC audio file"
        case .alac: "Apple Lossless audio file"
        case .mp3: "MPEG audio file"
        case .flac: "FLAC audio file"
        case .aiff: "AIFF audio file"
        case .wav: "WAV audio file"
        }
    }

    /// The format marker at `mhit` 0x90: 0x0C for MP3, 0x33 for MPEG-4 audio.
    var iTunesFormatMarker: UInt16 {
        self == .mp3 ? 0x000C : 0x0033
    }
}
