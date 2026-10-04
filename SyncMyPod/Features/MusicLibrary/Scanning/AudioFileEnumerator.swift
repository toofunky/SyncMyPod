import Foundation

nonisolated struct AudioFileEnumerator {
    private static let fileExtensions: Set = ["m4a", "mp3", "flac"]
    private static let resourceKeys: [URLResourceKey] = [
        .isRegularFileKey, .fileSizeKey, .contentModificationDateKey,
    ]

    func files(in folderURL: URL) throws -> [ScannedAudioFile] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: folderURL.path(percentEncoded: false),
                                             isDirectory: &isDirectory), isDirectory.boolValue,
              let enumerator = FileManager.default.enumerator(
            at: folderURL, includingPropertiesForKeys: Self.resourceKeys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            throw CocoaError(.fileReadNoSuchFile, userInfo: [NSURLErrorKey: folderURL])
        }
        return enumerator.compactMap { ($0 as? URL).flatMap(scannedFile) }
    }

    func scannedFile(at url: URL) -> ScannedAudioFile? {
        guard Self.fileExtensions.contains(url.pathExtension.lowercased()),
              let values = try? url.resourceValues(forKeys: Set(Self.resourceKeys)),
              values.isRegularFile == true else { return nil }
        return ScannedAudioFile(url: url, fileSize: values.fileSize ?? 0,
                                modificationDate: values.contentModificationDate ?? .distantPast)
    }
}
