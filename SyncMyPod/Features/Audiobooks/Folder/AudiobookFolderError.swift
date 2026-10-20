import Foundation

nonisolated enum AudiobookFolderError: LocalizedError, Equatable {
    case overlapsLibrary(String)
    case overlapsPodcasts(String)

    var errorDescription: String? {
        switch self {
        case .overlapsLibrary(let path):
            "Your audiobook folder can't be inside or around your music folder “\(path)”, or scanning it "
                + "would add every book to your music library. Choose a folder outside it."
        case .overlapsPodcasts(let path):
            "Your audiobook folder can't be inside or around your podcast folder “\(path)”, or scanning it "
                + "would list every episode as an audiobook. Choose a folder outside it."
        }
    }
}
