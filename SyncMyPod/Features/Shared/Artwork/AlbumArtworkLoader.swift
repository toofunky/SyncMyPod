import CoreGraphics
import Foundation

/// Caches album covers by fingerprint and limits how many files are read at once,
/// since the library lives on a spinning drive.
final class AlbumArtworkLoader {
    static let live = AlbumArtworkLoader()

    private static let maxConcurrentReads = 2
    private static let cacheCostLimit = 256 * 1024 * 1024
    private static let thumbnailPixelSize = 600

    private let reader = CoverArtThumbnailReader(maxPixelSize: thumbnailPixelSize)
    private let cache = NSCache<NSString, CGImage>()
    private var activeReads = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init() {
        cache.totalCostLimit = Self.cacheCostLimit
    }

    func cachedArtwork(for fingerprint: String) -> CGImage? {
        cache.object(forKey: fingerprint as NSString)
    }

    func artwork(path: String, fingerprint: String) async -> CGImage? {
        if let cached = cachedArtwork(for: fingerprint) { return cached }
        await acquireReadSlot()
        defer { releaseReadSlot() }
        if let cached = cachedArtwork(for: fingerprint) { return cached }
        guard !Task.isCancelled, let art = try? await reader.read(URL(filePath: path)) else { return nil }
        cache.setObject(art.image, forKey: fingerprint as NSString, cost: art.image.bytesPerRow * art.image.height)
        return art.image
    }

    private func acquireReadSlot() async {
        guard activeReads >= Self.maxConcurrentReads else {
            activeReads += 1
            return
        }
        await withCheckedContinuation { waiters.append($0) }
    }

    /// Hands the slot to the newest waiter, which is the most likely to still be on screen.
    private func releaseReadSlot() {
        if let next = waiters.popLast() {
            next.resume()
        } else {
            activeReads -= 1
        }
    }
}
