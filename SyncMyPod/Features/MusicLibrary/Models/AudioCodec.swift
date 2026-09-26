import CoreMedia

nonisolated enum AudioCodec: String, Codable, Sendable {
    case aac
    case alac
    case mp3

    init?(_ subType: CMFormatDescription.MediaSubType) {
        switch subType {
        case .mpeg4AAC: self = .aac
        case .appleLossless: self = .alac
        case .mpegLayer3: self = .mp3
        default: return nil
        }
    }

    var displayName: String { rawValue.uppercased() }
}
