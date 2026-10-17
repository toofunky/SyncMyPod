import Foundation

nonisolated enum PodcastFolderError: LocalizedError, Equatable {
    case overlapsLibrary(String)

    var errorDescription: String? {
        switch self {
        case .overlapsLibrary(let path):
            "Podcasts can't be downloaded into or around your music folder “\(path)”, or scanning it "
                + "would add every episode to your music library. Choose a folder outside it."
        }
    }
}
