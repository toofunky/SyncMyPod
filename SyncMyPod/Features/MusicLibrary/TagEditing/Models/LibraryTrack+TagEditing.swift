import Foundation

extension LibraryTrack {
    /// Re-reads the file after its tags were written, as a rescan would.
    func refresh(from url: URL) async throws {
        guard let file = AudioFileEnumerator().scannedFile(at: url),
              let metadata = try await AudioMetadataReader().read(url) else {
            throw CocoaError(.fileReadCorruptFile, userInfo: [NSURLErrorKey: url])
        }
        update(file: file, metadata: metadata)
    }
}
