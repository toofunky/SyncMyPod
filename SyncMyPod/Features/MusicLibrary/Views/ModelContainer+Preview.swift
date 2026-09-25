import SwiftData

#if DEBUG
extension ModelContainer {
    static let preview: ModelContainer = {
        let container = makeInMemory()
        container.mainContext.insert(LibraryFolder.preview)
        LibraryTrack.previewTracks.forEach(container.mainContext.insert)
        return container
    }()

    static let emptyPreview = makeInMemory()

    static func makeInMemory() -> ModelContainer {
        do {
            return try ModelContainer(for: Schema(MusicLibrarySchema.models),
                                      configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        } catch {
            fatalError("Couldn't create in-memory container: \(error)")
        }
    }
}
#endif
