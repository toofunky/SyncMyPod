import SwiftData

nonisolated enum MusicLibrarySchema {
    static var models: [any PersistentModel.Type] { [LibraryFolder.self, LibraryTrack.self] }
}
