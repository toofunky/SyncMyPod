import CoreMedia

nonisolated enum AudioCodec: String, Codable, Sendable {
    case aac
    case alac
    case mp3
    case flac
    case aiff
    case wav

    static let aiffExtensions: Set = ["aif", "aiff", "aifc"]
    static let wavExtensions: Set = ["wav"]

    init?(_ subType: CMFormatDescription.MediaSubType) {
        switch subType {
        case .mpeg4AAC: self = .aac
        case .appleLossless: self = .alac
        case .mpegLayer3: self = .mp3
        case .flac: self = .flac
        default: return nil
        }
    }

    /// AIFF and WAV both hold uncompressed PCM, so they're told apart by their extension. Other audio in
    /// those containers isn't supported, since its tags couldn't be written.
    init?(_ subType: CMFormatDescription.MediaSubType, fileExtension: String) {
        let ext = fileExtension.lowercased()
        let isPCM = subType == .linearPCM
        if Self.aiffExtensions.contains(ext) {
            guard isPCM else { return nil }
            self = .aiff
        } else if Self.wavExtensions.contains(ext) {
            guard isPCM else { return nil }
            self = .wav
        } else {
            self.init(subType)
        }
    }

    var displayName: String { rawValue.uppercased() }

    /// Songs aren't transcoded, so only the formats an iPod sync is meant for go to iPods. The rest go only
    /// to other players.
    var syncsToIPod: Bool {
        switch self {
        case .aac, .alac, .mp3: true
        case .flac, .aiff, .wav: false
        }
    }
}
