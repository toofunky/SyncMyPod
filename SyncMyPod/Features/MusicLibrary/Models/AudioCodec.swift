import CoreMedia

nonisolated enum AudioCodec: String, Codable, Sendable {
    case aac
    case alac
    case mp3
    case flac

    init?(_ subType: CMFormatDescription.MediaSubType) {
        switch subType {
        case .mpeg4AAC: self = .aac
        case .appleLossless: self = .alac
        case .mpegLayer3: self = .mp3
        case .flac: self = .flac
        default: return nil
        }
    }

    var displayName: String { rawValue.uppercased() }

    /// iPods can't play FLAC, and songs aren't transcoded, so FLAC only goes to other players.
    var syncsToIPod: Bool { self != .flac }
}
