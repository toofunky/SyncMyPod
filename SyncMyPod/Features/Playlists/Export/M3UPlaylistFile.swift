import CoreTransferable
import UniformTypeIdentifiers

/// The text of an exported `.m3u8`, for `fileExporter`.
nonisolated struct M3UPlaylistFile: Transferable {
    let contents: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .m3uPlaylist) { Data($0.contents.utf8) }
    }
}
