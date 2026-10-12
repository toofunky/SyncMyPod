import Foundation

/// The kind of playlist file written to a player, and the text encoding it's read in.
nonisolated enum PlayerPlaylistFormat: String, Codable, CaseIterable, Identifiable, Sendable {
    case m3u8
    case m3u

    var id: Self { self }
    var fileExtension: String { rawValue }
    var encoding: String.Encoding { self == .m3u ? .windowsCP1252 : .utf8 }

    var title: String {
        switch self {
        case .m3u8: ".m3u8 (UTF-8)"
        case .m3u: ".m3u (Windows Latin-1)"
        }
    }

    init?(fileName: String) {
        self.init(rawValue: (fileName as NSString).pathExtension.lowercased())
    }

    /// Precomposed first, since macOS often stores "é" as "e" and a separate accent that Latin-1 lacks.
    func canEncode(_ text: String) -> Bool {
        text.precomposedStringWithCanonicalMapping.canBeConverted(to: encoding)
    }

    /// Characters the encoding lacks become "?".
    func encoded(_ text: String) -> Data {
        text.precomposedStringWithCanonicalMapping.data(using: encoding, allowLossyConversion: true) ?? Data()
    }

    func decoded(_ data: Data) -> String? {
        String(data: data, encoding: encoding)
    }

    /// The text as it reads back from a file, so unchanged playlists compare equal.
    func representable(_ text: String) -> String {
        decoded(encoded(text)) ?? text
    }
}
