import Foundation

/// Names that are safe on the FAT32 and exFAT cards most players use.
nonisolated enum PlayerFileNamer {
    private static let maxComponentLength = 120
    private static let forbidden = CharacterSet(charactersIn: "/\\:*?\"<>|").union(.controlCharacters)

    /// Replaces characters FAT can't store, keeps names from hiding behind a leading dot, and trims the
    /// trailing dots and spaces Windows drops.
    static func safeComponent(_ name: String, fallback: String) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in name.unicodeScalars {
            scalars.append(forbidden.contains(scalar) ? "_" : scalar)
        }
        var safe = String(String(scalars).prefix(maxComponentLength)).trimmingCharacters(in: .whitespaces)
        while safe.hasSuffix(".") || safe.hasSuffix(" ") { safe.removeLast() }
        if safe.hasPrefix(".") { safe = "_" + safe.dropFirst() }
        return safe.isEmpty ? fallback : safe
    }

    /// "07" on a single-disc album, "2-07" when it has more than one disc; `nil` without a track number.
    static func numberPrefix(disc: Int, discCount: Int, track: Int, trackCount: Int) -> String? {
        guard track > 0 else { return nil }
        let width = max(2, String(trackCount).count)
        let number = String(repeating: "0", count: max(0, width - String(track).count)) + String(track)
        return discCount > 1 || disc > 1 ? "\(max(disc, 1))-\(number)" : number
    }

    /// "Song (2).m4a" for the second file that would take "Song.m4a".
    static func numbered(_ path: String, copy: Int) -> String {
        let ext = (path as NSString).pathExtension
        let stem = (path as NSString).deletingPathExtension
        return ext.isEmpty ? "\(stem) (\(copy))" : "\(stem) (\(copy)).\(ext)"
    }
}
