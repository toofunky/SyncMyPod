import AVFoundation
import CryptoKit

/// A hash of the embedded cover's encoded bytes, for telling a changed cover from an unchanged one.
nonisolated enum CoverArtFingerprint {
    static func of(_ items: [AVMetadataItem]) async -> String? {
        guard let item = items.coverArt,
              let data = try? await item.load(.dataValue) else { return nil }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
