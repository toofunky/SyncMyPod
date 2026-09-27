import Foundation
import SwiftData

/// Keeps the music folder's security scope open for the app's lifetime, so reading library files by path
/// uses the access granted when the folder was chosen instead of triggering another volume-access prompt.
@MainActor
final class LibraryFolderAccess {
    static let shared = LibraryFolderAccess()

    private var openURL: URL?

    private init() {}

    func open(in context: ModelContext) {
        guard let folder = try? context.fetch(FetchDescriptor<LibraryFolder>()).first else { return }
        _ = try? open(folder)
    }

    @discardableResult
    func open(_ folder: LibraryFolder) throws -> URL {
        let url = try folder.resolveURL()
        guard url != openURL else { return url }
        openURL?.stopAccessingSecurityScopedResource()
        openURL = url.startAccessingSecurityScopedResource() ? url : nil
        return url
    }
}
