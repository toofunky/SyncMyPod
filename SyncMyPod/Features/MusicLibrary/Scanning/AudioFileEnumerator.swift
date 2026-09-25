import Foundation

nonisolated struct AudioFileEnumerator {
    private static let fileExtension = "m4a"
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

    private func scannedFile(at url: URL) -> ScannedAudioFile? {
        guard url.pathExtension.lowercased() == Self.fileExtension,
              let values = try? url.resourceValues(forKeys: Set(Self.resourceKeys)),
              values.isRegularFile == true else { return nil }
        return ScannedAudioFile(url: url, fileSize: values.fileSize ?? 0,
                                modificationDate: values.contentModificationDate ?? .distantPast)
    }
}
